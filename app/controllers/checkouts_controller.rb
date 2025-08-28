class CheckoutsController < ApplicationController
  def create
    cart = params[:cart]
    cep_destino = params[:cep_destino]
    Rails.logger.info "Received cart: #{cart.inspect}"
    Rails.logger.info "Received cep_destino: #{cep_destino}"

    begin
      line_items = cart.map do |item|
        product = Product.find(item["id"])
        product_stock = product.stocks.find { |ps| ps.size == item["size"] }

        if product_stock.nil?
          Rails.logger.info "Stock not found for product #{product.id}, size #{item['size']}"
          render json: { error: "Tamanho #{item['size']} não disponível para #{product.name}" }, status: :unprocessable_entity
          return
        end

        if product_stock.amount < item["quantity"].to_i
          Rails.logger.info "Insufficient stock: #{product_stock.amount} < #{item['quantity']}"
          render json: { error: "Estoque insuficiente para #{product.name} no tamanho #{item['size']}. Disponível: #{product_stock.amount}" }, status: :unprocessable_entity
          return
        end

        {
          quantity: item["quantity"].to_i,
          price_data: {
            currency: 'brl',
            product_data: {
              name: item["name"],
              metadata: { product_id: product.id, size: item["size"], product_stock_id: product_stock.id }
            },
            unit_amount: item["price"].to_i
          }
        }
      end

      # Calcular frete
      frete_valor = 0
      if cep_destino.present?
        begin
          calculador = Correios::Frete::Calculador.new(
            cep_origem: '83601-030',
            cep_destino: cep_destino,
            peso: 1,
            comprimento: 20,
            largura: 15,
            altura: 10
          )
          resultado = calculador.calcular(:sedex)
          frete_valor = (resultado.valor.to_s.gsub(",", ".").to_f * 100).to_i
        rescue => frete_error
          Rails.logger.error "Erro ao calcular frete: #{frete_error.message}"
        end
      end

      if frete_valor > 0
        line_items << {
          quantity: 1,
          price_data: {
            currency: 'brl',
            product_data: {
              name: 'Frete',
              metadata: { tipo: 'frete', cep_destino: cep_destino }
            },
            unit_amount: frete_valor
          }
        }
      end

      # Set Stripe API key
      stripe_secret_key = Rails.application.credentials.dig(:stripe, :secret_key)
      Stripe.api_key = stripe_secret_key

      session = Stripe::Checkout::Session.create(
        mode: "payment",
        line_items: line_items,
        success_url: "https://mysite-78e2.onrender.com/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "https://mysite-78e2.onrender.com/cancel",
        shipping_address_collection: {
          allowed_countries: ['BR']
        }
      )

      render json: { url: session.url }
      
    rescue => e
      Rails.logger.error "Checkout error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "Erro no servidor: #{e.message}" }, status: :internal_server_error
    end
  end

  def success
    @session_id = params[:session_id]
    Rails.logger.info "Success page - session_id: #{@session_id}"
    
    if @session_id
      stripe_secret_key = Rails.application.credentials.dig(:stripe, :secret_key)
      Stripe.api_key = stripe_secret_key
      
      begin
        Rails.logger.info "Retrieving Stripe session..."
        @session = Stripe::Checkout::Session.retrieve(@session_id)
        Rails.logger.info "Session retrieved: #{@session.id}"
        Rails.logger.info "Payment status: #{@session.payment_status}"
        
        # Procurar pelo stripe_session_id
        @order = Order.find_by(stripe_session_id: @session_id)
        Rails.logger.info "Order search result: #{@order.inspect}"
        
        # Se não encontrou o pedido e o pagamento foi confirmado, criar manualmente
        if @order.nil? && @session.payment_status == 'paid'
          Rails.logger.info "Creating order manually since webhook didn't process it"
          Rails.logger.info "Customer email: #{@session.customer_details.email}"
          Rails.logger.info "Amount total: #{@session.amount_total}"
          
          # Obter endereço de entrega se disponível
          address = ""
          if @session.collected_information&.shipping_details&.address
            addr = @session.collected_information.shipping_details.address
            address = "#{addr.line1}, #{addr.city} - #{addr.state}, #{addr.postal_code}"
            Rails.logger.info "Address: #{address}"
          elsif @session.customer_details&.address
            addr = @session.customer_details.address
            address = "#{addr.line1}, #{addr.city} - #{addr.state}, #{addr.postal_code}"
            Rails.logger.info "Address from customer_details: #{address}"
          end
          
          begin
            @order = Order.create!(
              customer_email: @session.customer_details.email,
              total: @session.amount_total,
              address: address,
              fulfilled: false,
              stripe_session_id: @session_id
            )
            
            Rails.logger.info "Order created successfully: #{@order.id}"
            
          rescue => order_error
            Rails.logger.error "Error creating order: #{order_error.class} - #{order_error.message}"
            Rails.logger.error order_error.backtrace.join("\n")
            @error = "Error creating order: #{order_error.message}"
          end
        elsif @order.nil?
          Rails.logger.warn "Payment status is not 'paid': #{@session.payment_status}"
        end
        
        Rails.logger.info "Final order state: #{@order&.id}"
        
      rescue Stripe::StripeError => e
        Rails.logger.error "Stripe error: #{e.message}"
        @error = "Unable to retrieve order details"
      rescue => e
        Rails.logger.error "Error in success action: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        @error = "Error processing order: #{e.message}"
      end
    else
      Rails.logger.warn "No session_id provided"
      @error = "No session ID provided"
    end
  end

  def cancel
    # Método para página de cancelamento
  end

  def calcular_frete
    cep_destino = params[:cep_destino].to_s.gsub(/\D/, '')
    
    begin
      # Adicionar timeout personalizado
      Timeout::timeout(3) do
        calculador = Correios::Frete::Calculador.new(
          cep_origem: '83601-030',
          cep_destino: cep_destino,
          peso: 1,
          comprimento: 20,
          largura: 15,
          altura: 10
        )

        resultado = calculador.calcular(:sedex)
        render json: { 
          valor: resultado.valor, 
          prazo: resultado.prazo_entrega,
          sucesso: true 
        }
        return
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error => e
      Rails.logger.error "Erro de timeout no cálculo do frete: #{e.message}"
    rescue => e
      Rails.logger.error "Erro no cálculo do frete: #{e.message}"
    end
    
    # Fallback: Calcular frete baseado na região do CEP
    frete_por_regiao = calcular_frete_por_regiao(cep_destino)
    render json: { 
      valor: frete_por_regiao[:valor], 
      prazo: frete_por_regiao[:prazo],
      sucesso: false,
      erro: "Valor calculado por região (serviço dos Correios indisponível)"
    }
  end

  private

  def calcular_frete_por_regiao(cep)
    # Remover hífen e converter para inteiro para comparação
    cep_num = cep.to_i
    
    case cep_num
    when 01000000..19999999 # São Paulo
      { valor: "15,50", prazo: "2-3 dias úteis" }
    when 20000000..28999999 # Rio de Janeiro  
      { valor: "18,00", prazo: "3-4 dias úteis" }
    when 29000000..29999999 # Espírito Santo
      { valor: "21,00", prazo: "4-5 dias úteis" }
    when 30000000..39999999 # Minas Gerais
      { valor: "17,00", prazo: "3-4 dias úteis" }
    when 40000000..48999999 # Paraná
      { valor: "13,00", prazo: "1-2 dias úteis" } # Mesmo estado
    when 49000000..49999999 # Santa Catarina
      { valor: "15,00", prazo: "2-3 dias úteis" }
    when 50000000..56999999 # Pernambuco, Alagoas
      { valor: "28,00", prazo: "5-7 dias úteis" }
    when 57000000..58999999 # Paraíba
      { valor: "29,00", prazo: "5-7 dias úteis" }
    when 59000000..59999999 # Rio Grande do Norte  
      { valor: "30,00", prazo: "5-7 dias úteis" }
    when 60000000..63999999 # Ceará
      { valor: "31,00", prazo: "6-8 dias úteis" }
    when 64000000..64999999 # Piauí
      { valor: "33,00", prazo: "6-8 dias úteis" }
    when 65000000..65999999 # Maranhão
      { valor: "35,00", prazo: "7-9 dias úteis" }
    when 70000000..72999999, 73000000..73699999 # Brasília
      { valor: "23,00", prazo: "4-5 dias úteis" }
    when 74000000..76999999 # Goiás
      { valor: "25,00", prazo: "4-6 dias úteis" }
    when 77000000..77999999 # Tocantins
      { valor: "38,00", prazo: "7-10 dias úteis" }
    when 78000000..78899999 # Mato Grosso
      { valor: "31,00", prazo: "5-7 dias úteis" }
    when 79000000..79999999 # Mato Grosso do Sul
      { valor: "27,00", prazo: "4-6 dias úteis" }
    when 80000000..87999999 # Paraná (outras regiões)
      { valor: "14,00", prazo: "1-3 dias úteis" }
    when 88000000..89999999 # Santa Catarina (outras regiões)
      { valor: "17,00", prazo: "2-3 dias úteis" }
    when 90000000..99999999 # Rio Grande do Sul
      { valor: "19,00", prazo: "3-4 dias úteis" }
    else
      { valor: "21,00", prazo: "3-5 dias úteis" } # Valor padrão
    end
  end

end

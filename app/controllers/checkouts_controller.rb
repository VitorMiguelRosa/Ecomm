class CheckoutsController < ApplicationController
  def create
    cart = params[:cart]
    
    Rails.logger.info "Received cart: #{cart.inspect}"
    
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
end
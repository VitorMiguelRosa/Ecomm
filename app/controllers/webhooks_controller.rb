class WebhooksController < ApplicationController
  skip_forgery_protection

  def stripe
    stripe_secret_key = Rails.application.credentials.dig(:stripe, :secret_key)
    Stripe.api_key = stripe_secret_key
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret) 
    event = nil

    begin
      if endpoint_secret.present?
        event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      else
        # Para desenvolvimento local sem verificação de assinatura
        Rails.logger.warn "No webhook secret found, parsing JSON directly"
        event = JSON.parse(payload, symbolize_names: true)
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON payload: #{e.message}"
      render json: { error: 'Invalid payload' }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Webhook signature verification failed: #{e.message}"
      render json: { error: 'Invalid signature' }, status: 400
      return
    end

    Rails.logger.info "Received webhook event: #{event[:type] || event['type']}"

    case event[:type] || event['type']
    when 'checkout.session.completed'
      session = event[:data][:object] || event['data']['object']
      shipping_details = session[:shipping_details] || session["shipping_details"]
      
      Rails.logger.info "Processing session: #{session[:id] || session['id']}"
      
      if shipping_details
        address_data = shipping_details[:address] || shipping_details["address"]
        address = "#{address_data[:line1] || address_data['line1']} #{address_data[:city] || address_data['city']}, #{address_data[:state] || address_data['state']} #{address_data[:postal_code] || address_data['postal_code']}"
      else
        address = ""
      end
      
      begin
        # Verificar se o pedido já foi criado
        existing_order = Order.find_by(stripe_session_id: session[:id] || session["id"])
        if existing_order
          Rails.logger.info "Order already exists: #{existing_order.id}"
          render json: { message: 'success' }
          return
        end
        
        # Criar o pedido
        customer_details = session[:customer_details] || session["customer_details"]
        order = Order.create!(
          customer_email: customer_details[:email] || customer_details["email"], 
          total: session[:amount_total] || session["amount_total"], 
          address: address, 
          fulfilled: false,
          stripe_session_id: session[:id] || session["id"],
          status: 'paid'
        )
        
        Rails.logger.info "Order created: #{order.id}"
        
        # Recuperar line items
        full_session = Stripe::Checkout::Session.retrieve({
          id: session[:id] || session["id"],
          expand: ['line_items']
        })
        
        line_items = full_session.line_items
        line_items["data"].each do |item|
          product = Stripe::Product.retrieve(item["price"]["product"])
          product_id = product["metadata"]["product_id"].to_i
          size = product["metadata"]["size"]
          quantity = item["quantity"]
          
          Rails.logger.info "Creating OrderProduct: product_id=#{product_id}, size=#{size}, quantity=#{quantity}"
          
          OrderProduct.create!(
            order: order, 
            product_id: product_id, 
            quantity: quantity, 
            size: size
          )
          
          # Atualizar estoque
          if product["metadata"]["product_stock_id"].present?
            stock = Stock.find(product["metadata"]["product_stock_id"])
            stock.decrement!(:amount, quantity)
            Rails.logger.info "Stock updated for product_stock_id: #{product['metadata']['product_stock_id']}"
          end
        end
        
        Rails.logger.info "Order processing completed for: #{order.id}"
        
      rescue => e
        Rails.logger.error "Error processing order: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
      
    else
      Rails.logger.info "Unhandled event type: #{event[:type] || event['type']}" 
    end

    render json: { message: 'success' }
  end
end
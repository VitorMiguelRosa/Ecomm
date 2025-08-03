class CheckoutsController < ApplicationController
  def create
    cart = params[:cart]
    line_items = cart.map do |item|
      product = Product.find(item["id"])
      product_stock = product.stocks.find { |ps| ps.size == item["size"] }

      if product_stock.amount < item["quantity"].to_i
        flash[:error] = "Insufficient stock for #{product.name} in size #{item['size']}"
        redirect_to cart_path and return
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
      success_url: "http://localhost:3000/success?session_id={CHECKOUT_SESSION_ID}",  # Added session_id parameter
      cancel_url: "http://localhost:3000/cancel",
      shipping_address_collection: {
        allowed_countries: ['BR']
      }
    )

    render json: { url: session.url }
  end

  def success
    @session_id = params[:session_id]
    
    if @session_id
      # Retrieve the Stripe session to get order details
      stripe_secret_key = Rails.application.credentials.dig(:stripe, :secret_key)
      Stripe.api_key = stripe_secret_key
      
      begin
        @session = Stripe::Checkout::Session.retrieve(@session_id)
        
        # Find the order created by the webhook
        @order = Order.find_by(
          customer_email: @session.customer_details.email, 
          total: @session.amount_total,
          created_at: 5.minutes.ago..Time.current
        )
      rescue Stripe::StripeError => e
        Rails.logger.error "Stripe error: #{e.message}"
        @error = "Unable to retrieve order details"
      end
    end
  end

  def cancel
    render :cancel
  end
end
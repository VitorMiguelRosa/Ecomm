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

    session = Stripe::Checkout::Session.create(
      mode: "payment",
      line_items: line_items,
      success_url: "https://localhost:3000/success",
      cancel_url: "https://localhost:3000/cancel",
      shipping_address_collection: {
        allowed_countries: ['BR']
      }
    )

    render json: { url: session.url }
  end
end
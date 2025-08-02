class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])
    @stock = @product.stocks.first
    @total_stock = @product.stocks.sum(:amount)
  end
end
# app/controllers/admin/stocks_controller.rb

class Admin::StocksController < AdminController
  # 1. New: Add set_product before_action for all relevant actions
  before_action :set_product
  before_action :set_admin_stock, only: %i[ show edit update destroy ]

  # GET /admin/products/:product_id/stocks or /admin/products/:product_id/stocks.json
  def index
    # 3. Corrected: Scope to the product's stocks
    @admin_stocks = @product.stocks.all
    # Your view file (index.html.erb) should be:
    # <% if @admin_stocks.any? %>
    #   <% @admin_stocks.each do |admin_stock| %>
    #     <%= render admin_stock %>
    #   <% end %>
    # <% else %>
    #   <p>No stocks found for this product.</p>
    # <% end %>
  end

  # GET /admin/products/:product_id/stocks/1 or /admin/products/:product_id/stocks/1.json
  def show
    # @admin_stock is set by set_admin_stock, which is now scoped.
  end

  # GET /admin/products/:product_id/stocks/new
  def new
    # 5. Corrected: Build the new stock through the product association
    @admin_stock = @product.stocks.new
    # @product is set by before_action :set_product
  end

  # GET /admin/products/:product_id/stocks/1/edit
  def edit
    # @admin_stock is set by set_admin_stock.
  end

  # POST /admin/products/:product_id/stocks or /admin/products/:product_id/stocks.json
  def create
    # @product is set by before_action :set_product
    @admin_stock = @product.stocks.build(admin_stock_params)

    respond_to do |format|
      if @admin_stock.save
        # Redirect to the show page for the newly created stock (correct path)
        format.html { redirect_to admin_product_stock_url(@product, @admin_stock), notice: "Stock was successfully created." }
        format.json { render :show, status: :created, location: @admin_stock }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_stock.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/products/:product_id/stocks/1 or /admin/products/:product_id/stocks/1.json
  def update
    # @admin_stock is set by set_admin_stock.
    respond_to do |format|
      if @admin_stock.update(admin_stock_params)
        # Redirect to the show page for the updated stock (correct path)
        format.html { redirect_to admin_product_stock_url(@product, @admin_stock), notice: "Stock was successfully updated." }
        format.json { render :show, status: :ok, location: @admin_stock }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_stock.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/products/:product_id/stocks/1 or /admin/products/:product_id/stocks/1.json
  def destroy
    # @admin_stock is set by set_admin_stock.
    @admin_stock.destroy!

    respond_to do |format|
      # 4. Corrected: Redirect to the index page for stocks of THIS product
      format.html { redirect_to admin_product_stocks_path(@product), status: :see_other, notice: "Stock was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # New: Add set_product method to find the parent product
    def set_product
      @product = Product.find(params[:product_id])
    end

    # 2. Corrected: Scope the find to the @product's stocks for security and correctness
    def set_admin_stock
      @admin_stock = @product.stocks.find(params[:id])
    end

    # 2. Corrected: params.require(:stock) instead of :admin_stock
    def admin_stock_params
      params.require(:stock).permit(:amount, :size)
    end
end
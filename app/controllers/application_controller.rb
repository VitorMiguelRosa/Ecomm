class ApplicationController < ActionController::Base
  include Pagy::Backend
  
  before_action :set_main_categories

  private

  def set_main_categories
    @main_categories = Category.all
  end
end

class ApplicationController < ActionController::Base
  before_action :set_main_categories

  private

  def set_main_categories
    @main_categories = Category.all
  end
end

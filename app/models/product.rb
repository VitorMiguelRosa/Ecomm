class Product < ApplicationRecord
  belongs_to :category
  has_many :stocks, dependent: :destroy
  has_many :order_products, dependent: :destroy
  has_many :orders, through: :order_products
  has_many_attached :images do |attachable|
    attachable.variant :thumb, resize_to_limit: [50, 50]
    attachable.variant :medium, resize_to_limit: [250, 250]
    attachable.variant :large, resize_to_limit: [500, 500]
  end
  
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true
  
  def price_in_currency
    (price / 100.0).round(2)
  end
  
  def formatted_price
    "R$ #{price_in_currency}"
  end
  
  def available_sizes
    stocks.where('amount > 0').pluck(:size)
  end
  
  def stock_for_size(size)
    stocks.find_by(size: size)&.amount || 0
  end
end

class Order < ApplicationRecord
  has_many :order_products, dependent: :destroy
  has_many :products, through: :order_products
  
  validates :customer_email, presence: true
  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :stripe_session_id, presence: true, uniqueness: true
  
  enum status: { pending: 0, paid: 1, shipped: 2, delivered: 3, cancelled: 4 }
  
  # Métodos auxiliares
  def total_in_currency
    (total / 100.0).round(2)
  end
  
  def formatted_total
    "R$ #{total_in_currency}"
  end
  
  def items_count
    order_products.sum(:quantity)
  end
end

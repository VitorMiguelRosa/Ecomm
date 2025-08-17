class OrderProduct < ApplicationRecord
  belongs_to :order
  belongs_to :product
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :size, presence: true
  
  # Método para calcular o subtotal
  def subtotal
    quantity * product.price
  end
  
  def formatted_subtotal
    "R$ #{(subtotal / 100.0).round(2)}"
  end
end

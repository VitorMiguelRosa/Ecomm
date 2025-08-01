class Product < ApplicationRecord
  has_many_attached :images do |attachable|
    attachable.variant :thumb, resize_to_limit: [50, 50]
    attachable.variant :medium, resize_to_limit: [250, 250]
  end
  belongs_to :category
  has_many :stocks, dependent: :destroy
  has_many :order_products, dependent: :destroy
end

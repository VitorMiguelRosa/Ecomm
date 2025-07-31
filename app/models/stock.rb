class Stock < ApplicationRecord
  self.table_name = "admin_stocks"
  belongs_to :product
end

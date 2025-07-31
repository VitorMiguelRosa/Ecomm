class CreateStocks < ActiveRecord::Migration[7.1]
  def change
    create_table :stocks do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.decimal :price

      t.timestamps
    end
  end
end

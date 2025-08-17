# db/migrate/create_orders.rb
class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.string :customer_email, null: false
      t.integer :total, null: false # em centavos
      t.text :address
      t.boolean :fulfilled, default: false
      t.string :stripe_session_id
      t.integer :status, default: 0
      
      t.timestamps
    end
    
    add_index :orders, :customer_email
    add_index :orders, :stripe_session_id, unique: true
    add_index :orders, :status
  end
end
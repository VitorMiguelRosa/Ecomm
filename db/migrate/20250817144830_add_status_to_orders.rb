class AddStatusToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :stripe_session_id, :string
    add_index :orders, :stripe_session_id, unique: true
    add_column :orders, :status, :integer, default: 0
    add_index :orders, :status
  end
end
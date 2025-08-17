class AddStripeSessionIdToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :stripe_session_id, :string
  end
end

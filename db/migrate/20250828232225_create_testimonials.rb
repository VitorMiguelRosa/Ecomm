class CreateTestimonials < ActiveRecord::Migration[7.1]
  def change
    create_table :testimonials do |t|
      t.string :customer_name, null: false
      t.text :content, null: false
      t.integer :position, null: false
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :testimonials, :position, unique: true
    add_index :testimonials, :active
  end
end

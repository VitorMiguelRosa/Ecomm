class Testimonial < ApplicationRecord
  validates :customer_name, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { maximum: 500 }
  validates :position, presence: true, inclusion: { in: 1..3 }, uniqueness: true
  
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position) }
  scope :for_display, -> { active.ordered.limit(3) }
  
  before_validation :set_next_position, if: :new_record?
  
  private
  
  def set_next_position
    return if position.present?
    
    max_position = self.class.maximum(:position) || 0
    if max_position < 3
      self.position = max_position + 1
    else
      self.position = 1 # Replace the first one if all positions are taken
    end
  end
end

class Event < ApplicationRecord

  has_many :opening_slots, foreign_key: "opening_id", class_name: "Slot"

end

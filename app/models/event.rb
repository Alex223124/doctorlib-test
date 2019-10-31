class Event < ApplicationRecord

  has_many :opening_slots, foreign_key: "opening_id", class_name: "Slot"
  has_many :appointment_slots, foreign_key: "appointment_id"
  has_many :booked_slots, through: :appointment_slots, source: :slot

end

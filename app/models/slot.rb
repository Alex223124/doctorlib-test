class Slot < ApplicationRecord

  belongs_to :opening, :class_name => "Event", required: true
  has_many :appointment_slots
  has_many :appointments, through: :appointment_slots, source: :event

end
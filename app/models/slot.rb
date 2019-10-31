class Slot < ApplicationRecord

  belongs_to :opening, :class_name => "Event", required: true
  has_many :appointment_slots
  has_many :appointments, through: :appointment_slots, source: :event

  validates_presence_of :begins_at_date, :begins_at_time, :day_of_the_week

end
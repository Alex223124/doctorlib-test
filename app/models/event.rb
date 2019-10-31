class Event < ApplicationRecord

  KINDS = ["opening", 'appointment'].freeze

  has_many :opening_slots, foreign_key: "opening_id", class_name: "Slot"
  has_many :appointment_slots, foreign_key: "appointment_id"
  has_many :booked_slots, through: :appointment_slots, source: :slot

  validates_presence_of :starts_at, :ends_at, :kind
  validates :kind, inclusion: { in: KINDS, message: "%{value} is not valid. Should be one: #{KINDS.join(" OR ")}"  }

  validates_with Validators::Event::DateRange, if: :is_opening?

end

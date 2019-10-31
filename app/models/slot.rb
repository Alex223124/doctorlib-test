class Slot < ApplicationRecord

  MINUTES_IN_ONE_SLOT = 30.freeze
  HALF_AN_HOUR_IN_SECONDS = 1800.freeze
  SECONDS_IN_ONE_MINUTE = 60.freeze

  belongs_to :opening, :class_name => "Event", required: true
  has_many :appointment_slots
  has_many :appointments, through: :appointment_slots, source: :event

  validates_presence_of :begins_at_date, :begins_at_time, :day_of_the_week


  def self.possible_starts_at_time_marks(event)
    time_marks = Array.new(possible_slots_amount_in(event.date_range), event.starts_at_time)
    time_marks.each_with_index.map { |mark, index| mark + (index * HALF_AN_HOUR_IN_SECONDS) }
  end

  def self.possible_slots_amount_in(date_range)
    date_range / (MINUTES_IN_ONE_SLOT * SECONDS_IN_ONE_MINUTE)
  end

end
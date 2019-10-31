# frozen_string_literal: true
class Event < ApplicationRecord

  KINDS = ["opening", 'appointment'].freeze

  has_many :opening_slots, foreign_key: "opening_id", class_name: "Slot"
  has_many :appointment_slots, foreign_key: "appointment_id"
  has_many :booked_slots, through: :appointment_slots, source: :slot

  validates_presence_of :starts_at, :ends_at, :kind
  validates :kind, inclusion: { in: KINDS, message: "%{value} is not valid. Should be one: #{KINDS.join(" OR ")}"  }

  validates_with Validators::Event::DateRange, if: :is_opening?
  validates_with Validators::Event::ConflictingSlots, if: :is_opening?
  validates_with Validators::Event::SlotsPresence, if: :is_appointment?

  def self.availabilities(starts_at)
    return if starts_at < Time.now
    service = Services::Slots::Availabilities.new(starts_at)
    service.call
  end

  def is_opening?
    kind == "opening"
  end

  def is_appointment?
    kind == "appointment"
  end

  def is_weekly?
    weekly_recurring == true
  end

  def starts_at_time
    in_seconds(starts_at)
  end

  def in_seconds(time)
    time.seconds_since_midnight.to_i
  end

  def day_of_the_week
    starts_at.wday
  end

  def date_range
    ends_at - starts_at
  end

  def ends_at_time
    in_seconds(ends_at)
  end

end

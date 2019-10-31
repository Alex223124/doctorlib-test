class Slot < ApplicationRecord

  MINUTES_IN_ONE_SLOT = 30.freeze
  HALF_AN_HOUR_IN_SECONDS = 1800.freeze
  SECONDS_IN_ONE_MINUTE = 60.freeze

  belongs_to :opening, :class_name => "Event", required: true
  has_many :appointment_slots
  has_many :appointments, through: :appointment_slots, source: :event

  validates_presence_of :begins_at_date, :begins_at_time, :day_of_the_week

  scope :actual, -> { where("begins_at_date > ?", DateTime.current)}
  scope :opened_between_date, lambda {|starts_at, ends_at| where("begins_at_date >= ? AND begins_at_date <= ?", starts_at, ends_at)}
  scope :weekly, -> { where(is_weekly: true) }
  scope :not_weekly, -> { where(is_weekly: false) }
  scope :by_week_day, lambda {|week_day| where("day_of_the_week = ?", week_day)}
  scope :opened_between_time, lambda {|starts_at, ends_at| where("begins_at_time >= ? AND (begins_at_time + #{HALF_AN_HOUR_IN_SECONDS}) <= ?", starts_at, ends_at)}
  scope :not_booked_in_regular, -> { where(is_fully_booked: false) }


  def self.available_slots_for(event)
    Slot.available_regular_slots(event.starts_at, event.ends_at) +
    Slot.find_weekly_slots(event.starts_at_time, event.ends_at_time, event.day_of_the_week)
  end

  def self.available_regular_slots(starts_at, ends_at)
    actual.not_weekly.opened_between_date(starts_at, ends_at).not_booked_in_regular
  end

  def self.find_weekly_slots(starts_at_time, ends_at_time, week_day)
    weekly.by_week_day(week_day).opened_between_time(starts_at_time, ends_at_time)
  end

  def self.possible_starts_at_time_marks(event)
    time_marks = Array.new(possible_slots_amount_in(event.date_range), event.starts_at_time)
    time_marks.each_with_index.map { |mark, index| mark + (index * HALF_AN_HOUR_IN_SECONDS) }
  end

  def self.possible_slots_amount_in(date_range)
    date_range / (MINUTES_IN_ONE_SLOT * SECONDS_IN_ONE_MINUTE)
  end

  def ends_at_time
    begins_at_time + HALF_AN_HOUR_IN_SECONDS
  end

  def is_regular?
    is_weekly == false
  end

  def begins_at_hours
    Time.at(begins_at_time).utc.strftime("%H:%M")
  end
end
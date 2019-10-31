class Services::Slots::Availabilities

  DEFAULT_FUTURE_DAYS_FOR_CHECKING_AVAILABILITIES = 7.freeze

  def initialize(starts_at)
    @starts_at = starts_at
    @ends_at = future_date
  end

  def call
    slots = regular_slots_availabilities + weekly_slots_availabilities
    format(slots)
  end

  private

  def regular_slots_availabilities
    Slot.available_regular_slots(@starts_at, @ends_at)
  end

  def future_date
    @starts_at + DEFAULT_FUTURE_DAYS_FOR_CHECKING_AVAILABILITIES.days
  end

  def weekly_slots_availabilities
    Slot.available_weekly_slots(@starts_at, @ends_at)
  end

  def format(slots)
    slots = rebuild_collection_of_(slots)
    collection_of_results(slots)
  end

  def rebuild_collection_of_(slots)
    formatted_result = []
    slots.map { |slot| formatted_result << hash_from_(slot) }
    formatted_result
  end

  def collection_of_results(slots)
    result = []
    (@starts_at...@ends_at).each do |date|
      matches = matches_by_day(slots, date)
      result << single_result(date, matches)
    end
    result
  end

  def single_result(date, matches)
    { date: date.strftime("%Y-%m-%d"), slots: formatted_(matches) }
  end

  def hash_from_(slot)
    {slot.day_of_the_week => slot.begins_at_hours}
  end

  def matches_by_day(slots, date)
    slots.select { |slot| slot.keys[0] == date.wday}
  end

  def formatted_(matches)
    matches.map { |slot| slot.values }.flatten
  end

end
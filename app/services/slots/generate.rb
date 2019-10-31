class Services::Slots::Generate

  def initialize(event)
    @event = event
  end

  def call
    begins_at = first_slot_begins_at
    possible_slots_amount.times do
      slot = Slot.new(begins_at_date: begins_at,
                      begins_at_time: begins_at_time(begins_at),
                      opening: @event,
                      is_weekly: @event.weekly_recurring,
                      day_of_the_week: day_of_the_week )
      slot.save!
      begins_at = next_slot_(begins_at)
    end
  end

  private

  def first_slot_begins_at
    @event.starts_at
  end

  def next_slot_(begins_at)
    begins_at + Slot::MINUTES_IN_ONE_SLOT.minutes
  end

  def begins_at_time(begins_at)
    begins_at.seconds_since_midnight.to_i
  end

  def possible_slots_amount
    Slot.possible_slots_amount_in(@event.date_range).to_i
  end

  def day_of_the_week
    if @event.weekly_recurring
      @event.day_of_the_week
    end
  end

end
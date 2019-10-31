class Validators::Event::ConflictingSlots < ActiveModel::Validator

  def validate(record)
    if conflicting_slots_exists?(record)
      record.errors.add(:conflicting_slots, message)
    end
  end

  private

  def conflicting_slots_exists?(event)
    conflicting_slots(event).present?
  end

  def conflicting_slots(event)
    @conflicting_slots ||= (Slot.opened_between_date(event.starts_at, event.ends_at) +
                            Slot.find_weekly_slots(event.starts_at_time, event.ends_at_time, event.day_of_the_week))
  end

  def message
    "You can't create event. Please pick another 'start_at' end"\
    "'ends_at' during opening creation + weekly mark."
  end

end
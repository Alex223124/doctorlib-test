class Validators::Event::SlotsPresence < ActiveModel::Validator

  def validate(record)
    if matches_in_quantity?(record)
      #do nothing
    else
      record.errors.add(:slots_presence, message)
    end
  end

  private

  def matches_in_quantity?(record)
    matches_by_time?(record)
  end

  def matches_by_time?(record)
    possible_starts_at_time_marks(record).count == matches_by_time(record).count
  end

  def available_slots(record)
    @available_slots = Slot.available_slots_for(record)
  end

  def matches_by_time(record)
    available_slots(record).select { |slot| possible_starts_at_time_marks(record).include?(slot[:begins_at_time]) }
  end

  def possible_starts_at_time_marks(record)
    Slot.possible_starts_at_time_marks(record)
  end

  def message
    "Date range (from 'start_at' to 'ends_at') you specified for the appointment is not valid. "\
    "Please pick 'start_at' to 'ends_at' which fits available slots."
  end

end
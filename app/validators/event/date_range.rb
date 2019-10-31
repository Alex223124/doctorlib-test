class Validators::Event::DateRange < ActiveModel::Validator

  def validate(record)
    if is_sum_of_slots?(record)
      #do nothing
    else
      record.errors.add(:date_range, message)
    end
  end

  private

  def is_sum_of_slots?(event)
    possible_slots(event) > 0 && is_whole_number?(possible_slots(event))
  end

  def possible_slots(event)
    @possible_slots ||= Slot.possible_slots_amount_in(event.date_range)
  end

  def is_whole_number?(number)
    Integer(number) == number
  end

  def message
    "Date range (from 'start_at' to 'ends_at') "\
    "should consist of pieces 30 minutes each"
  end

end
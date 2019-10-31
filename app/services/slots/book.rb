class Services::Slots::Book

  def initialize(event)
    @event = event
  end

  def call
    available_slots(@event).each do |slot|
      slot.appointments << @event
      slot.is_fully_booked = true if slot.is_regular?
      slot.save!
    end
  end

  private

  def available_slots(event)
    Slot.available_slots_for(event)
  end

end
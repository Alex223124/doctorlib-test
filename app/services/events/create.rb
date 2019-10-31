class Services::Events::Create

  def initialize(*args)
    @args = args[0]
  end

  def call
    ActiveRecord::Base.transaction do
      initialize_event
      generate_slots if @event.is_opening?
      book_slots if @event.is_appointment?
      @event.save!
    end
    @event
  rescue StandardError => error
    error
  end

  private

  def initialize_event
    @event = Event.new(kind: @args[:kind], starts_at: @args[:starts_at],
                       ends_at: @args[:ends_at],
                       weekly_recurring: @args[:weekly_recurring])
  end

  def book_slots
    generator = Services::Slots::Book.new(@event)
    generator.call
  end

  def generate_slots
    generator = Services::Slots::Generate.new(@event)
    generator.call
  end

end
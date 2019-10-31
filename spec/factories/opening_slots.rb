FactoryBot.define do
  factory :opening_slot, class: 'Slot' do
    begins_at_date  { DateTime.now.beginning_of_hour + 9.hours }
    begins_at_time  { (DateTime.now.beginning_of_hour + 9.hours).seconds_since_midnight.to_i }
    is_fully_booked { false }
    is_weekly       { false }
    day_of_the_week { (DateTime.now.beginning_of_hour + 9.hours).wday }
  end

  trait :with_appointment_slot do
    after(:create) do |opening_slot|
      create(:appointment_slot, slot: opening_slot,
             event: create(:appointment_event,
                            starts_at: opening_slot.begins_at_date,
                            ends_at: opening_slot.begins_at_date + 30.minutes))
    end
  end
end
FactoryBot.define do
  factory :appointment_event, class: 'Event' do
    starts_at { DateTime.now.beginning_of_hour + 9.hours }
    ends_at   { DateTime.now.beginning_of_hour + 10.hours }
    kind      { "appointment" }
    weekly_recurring  { false }
  end

  trait :with_regular_opening_event do
    before(:create) do |appointment_event|
      create(:opening_event, :with_opening_slots,
             starts_at: appointment_event.starts_at,
             ends_at: appointment_event.ends_at)

    end
  end

  trait :with_weekly_opening_event do
    before(:create) do |appointment_event|
      create(:opening_event, :with_opening_slots,
             starts_at: appointment_event.starts_at,
             ends_at: appointment_event.ends_at + 3.hours,
             weekly_recurring: true)
    end
  end
end
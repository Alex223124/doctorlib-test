FactoryBot.define do
  factory :opening_event, class: 'Event' do
    starts_at { DateTime.now.beginning_of_hour + 9.hours }
    ends_at   { DateTime.now.beginning_of_hour + 10.hours + 30.minutes }
    kind      { "opening" }
    weekly_recurring  { false }
    transient do
      is_fully_booked { false }
    end
  end

  trait :with_opening_slots do
    before(:create) do |regular_opening_event, transient|
      create(:opening_slot, begins_at_date: regular_opening_event.starts_at,
              begins_at_time: regular_opening_event.starts_at.seconds_since_midnight.to_i,
              day_of_the_week: regular_opening_event.starts_at.beginning_of_day.wday,
              opening: regular_opening_event,
              is_weekly: regular_opening_event.weekly_recurring,
              is_fully_booked: transient.is_fully_booked)

      create(:opening_slot, begins_at_date: regular_opening_event.starts_at + 30.minutes,
             begins_at_time: (regular_opening_event.starts_at + 30.minutes).seconds_since_midnight.to_i,
             day_of_the_week: regular_opening_event.starts_at.beginning_of_day.wday,
             opening: regular_opening_event,
             is_weekly: regular_opening_event.weekly_recurring,
             is_fully_booked: transient.is_fully_booked)

      create(:opening_slot, begins_at_date: regular_opening_event.starts_at + 1.hour,
             begins_at_time: (regular_opening_event.starts_at + 1.hour).seconds_since_midnight.to_i,
             day_of_the_week: regular_opening_event.starts_at.beginning_of_day.wday,
             opening: regular_opening_event,
             is_weekly: regular_opening_event.weekly_recurring,
             is_fully_booked: transient.is_fully_booked)
    end
  end

  trait :with_booked_opening_slots do
    before(:create) do |regular_opening_event, transient|
      create(:opening_slot, :with_appointment_slot, begins_at_date: regular_opening_event.starts_at,
             begins_at_time: regular_opening_event.starts_at.seconds_since_midnight.to_i,
             day_of_the_week: regular_opening_event.starts_at.beginning_of_day.wday,
             opening: regular_opening_event,
             is_weekly: regular_opening_event.weekly_recurring,
             is_fully_booked: transient.is_fully_booked)

      create(:opening_slot, :with_appointment_slot, begins_at_date: regular_opening_event.starts_at + 30.minutes,
             begins_at_time: (regular_opening_event.starts_at + 30.minutes).seconds_since_midnight.to_i,
             day_of_the_week: regular_opening_event.starts_at.beginning_of_day.wday,
             opening: regular_opening_event,
             is_weekly: regular_opening_event.weekly_recurring,
             is_fully_booked: transient.is_fully_booked)

      create(:opening_slot, :with_appointment_slot, begins_at_date: regular_opening_event.starts_at + 1.hour,
             begins_at_time: (regular_opening_event.starts_at + 1.hour).seconds_since_midnight.to_i,
             day_of_the_week: regular_opening_event.starts_at.beginning_of_day.wday,
             opening: regular_opening_event,
             is_weekly: regular_opening_event.weekly_recurring,
             is_fully_booked: transient.is_fully_booked)
    end
  end
end
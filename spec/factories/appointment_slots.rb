FactoryBot.define do
  factory :appointment_slot do
    association :event, factory: :appointment_event
    association :slot, factory: :appointment, last_name: "Writely"
  end
end
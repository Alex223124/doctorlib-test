class AppointmentSlot < ApplicationRecord
  belongs_to :event, foreign_key: "appointment_id"
  belongs_to :slot
end
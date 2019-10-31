class CreateAppointmentSlots < ActiveRecord::Migration[5.2]
  def change
    create_table :appointment_slots, :id => false do |t|
      t.integer :appointment_id
      t.integer :slot_id
      t.index [:slot_id, :appointment_id]
      t.index [:appointment_id, :slot_id]
    end
  end
end
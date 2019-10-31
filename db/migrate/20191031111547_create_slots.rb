class CreateSlots < ActiveRecord::Migration[5.2]
  def change
    create_table :slots do |t|
      t.datetime :begins_at_date
      t.integer :begins_at_time
      t.boolean :is_fully_booked, default: false
      t.boolean :is_weekly, default: false
      t.integer :day_of_the_week
      t.references :opening, foreign_key: false
      t.timestamps
    end
    add_foreign_key :slots, :opening, column: :opening_id
  end
end
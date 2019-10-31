require 'rails_helper'

RSpec.describe Slot, type: :model do

  describe 'scopes' do

    describe '#actual' do

      context "when we have slots for future appointments" do

        before do
          Timecop.freeze DateTime.current
          create :opening_event, :with_opening_slots
          create :opening_event, :with_opening_slots, starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end
        after  { Timecop.return }

        it "should find all slots which are created for future appointments" do
          expect(Slot.all.count).to eql(6)
          expect(Slot.actual.count).to eql(3)
        end

        it "should generate correct sql query" do
          expected_result = "SELECT \"slots\".* FROM \"slots\" WHERE "\
                          "(begins_at_date > '#{DateTime.current.strftime("%F %T.%6N")}')"
          expect(Slot.actual.to_sql).to eql(expected_result)
        end
      end

      context "when we don't have slots for future appointments" do

        before do
          create :opening_event, :with_opening_slots, starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end

        it "should find 0 records" do
          expect(Slot.all.count).to eql(3)
          expected_result = 0
          expect(Slot.actual.count).to eql(expected_result)
        end
      end
    end

    describe '#opened_between_date' do

      context "when we have slots in expected date range" do

        before do
          Timecop.freeze DateTime.current
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          create :opening_event, :with_opening_slots, starts_at: @starts_at, ends_at: @ends_at
          create :opening_event, :with_opening_slots, starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end
        after  { Timecop.return }

        it "should find all slots in specified date range" do
          expect(Slot.all.count).to eql(6)
          expect(Slot.opened_between_date(@starts_at, @ends_at).count).to eql(2)
        end

        it "should generate correct sql query" do
          expected_result = "SELECT \"slots\".* FROM \"slots\" WHERE "\
                            "(begins_at_date >= '#{@starts_at.utc.strftime("%F %T")}' "\
                            "AND begins_at_date <= '#{@ends_at.utc.strftime("%F %T")}')"
          expect(Slot.opened_between_date(@starts_at, @ends_at).to_sql).to eql(expected_result)
        end
      end

      context "when we don't have slots in expected date range" do

        before do
          Timecop.freeze DateTime.current
          create :opening_event, :with_opening_slots, starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end
        after  { Timecop.return }

        it "should find 0 records" do
          expected_result = 0
          expect(Slot.all.count).to eql(3)
          expect(Slot.opened_between_date(@starts_at, @ends_at).count).to eql(expected_result)
        end
      end
    end

    describe '#opened_between_time' do

      context "when we have slots in expected time range" do

        before do
          Timecop.freeze DateTime.current
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          @opening = create :opening_event, :with_opening_slots, starts_at: @starts_at, ends_at: @ends_at
          create :opening_event, :with_opening_slots, starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end
        after  { Timecop.return }

        it "should find all slots in specified time range" do
          expect(Slot.all.count).to eql(6)
          expect(Slot.opened_between_time(@opening.starts_at_time, @opening.ends_at_time).count).to eql(1)
        end

        it "should generate correct sql query" do
          expected_result = "SELECT \"slots\".* FROM \"slots\" WHERE "\
                            "(begins_at_time >= #{@opening.starts_at_time} "\
                            "AND (begins_at_time + 1800) <= #{@opening.ends_at_time})"
          expect(Slot.all.count).to eql(6)
          expect(Slot.opened_between_time(@opening.starts_at_time,
                                          @opening.ends_at_time).to_sql).to eql(expected_result)
        end
      end

      context "when we don't have slots in expected time range" do

        before do
          Timecop.freeze DateTime.current
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          create :opening_event, :with_opening_slots, starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end
        after  { Timecop.return }

        it "should find 0 records" do
          expected_result = 0
          expect(Slot.all.count).to eql(3)
          expect(Slot.opened_between_time(@starts_at, @ends_at).count).to eql(expected_result)
        end
      end
    end

    describe '#not_booked_in_regular' do

      context "when we have regular slots which are not booked" do

        before do
          create :opening_event, :with_opening_slots
          create :opening_event, :with_opening_slots, is_fully_booked: true
        end

        it "should find all slots which are not booked in regular slots" do
          expect(Slot.all.count).to eql(6)
          expect(Slot.not_booked_in_regular.count).to eql(3)
        end

        it "should generate correct sql query" do
          expected_result = "SELECT \"slots\".* FROM \"slots\" WHERE \"slots\".\"is_fully_booked\" = 0"
          expect(Slot.all.count).to eql(6)
          expect(Slot.not_booked_in_regular.to_sql).to eql(expected_result)
        end
      end

      context "when we don't have regular slots which are not booked" do

        before do
          create :opening_event, :with_opening_slots
        end

        it "should find 0 records" do
          expected_result = 0
          expect(Slot.all.count).to eql(3)
          expect(Slot.opened_between_time(@starts_at, @ends_at).count).to eql(expected_result)
        end
      end
    end

    describe '#booked_in_weekly' do

      context "when we have weekly slots which are not booked" do

        before do
          Timecop.freeze DateTime.current
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          @opening = create :opening_event, :with_booked_opening_slots,
                            starts_at: @starts_at, ends_at: @ends_at,
                            weekly_recurring: true
          create :opening_event, :with_opening_slots,
                 starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end
        after  { Timecop.return }

        it "should find all slots which are not booked in weekly slots" do
          expect(Slot.all.count).to eql(6)
          expect(Slot.booked_in_weekly(@opening.starts_at.to_date,
                                       @opening.ends_at.to_date).count).to eql(3)
        end

        it "should generate correct sql query" do
          expected_result = "SELECT \"slots\".* FROM \"slots\" INNER "\
                          "JOIN \"appointment_slots\" ON \"appointment_slots\".\"slot_id\" = "\
                          "\"slots\".\"id\" INNER JOIN \"events\" ON \"events\".\"id\" = "\
                          "\"appointment_slots\".\"appointment_id\" WHERE \"slots\".\"is_weekly\" = "\
                          "1 AND (DATE(events.starts_at) >= '#{@starts_at.utc.strftime("%F")}' AND "\
                          "DATE(events.starts_at) <= '#{@starts_at.utc.strftime("%F")}')"
          expect(Slot.booked_in_weekly(@opening.starts_at.to_date,
                                       @opening.ends_at.to_date).to_sql).to eql(expected_result)
        end
      end

      context "when we don't have weekly slots which are not booked" do

        before do
          Timecop.freeze DateTime.current
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          @opening = create :opening_event, :with_opening_slots,
                            starts_at: @starts_at, ends_at: @ends_at,
                            weekly_recurring: true
          create :opening_event, :with_opening_slots,
                 starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end
        after  { Timecop.return }


        it "should find 0 records" do
          expected_result = 0
          expect(Slot.all.count).to eql(6)
          expect(Slot.booked_in_weekly(@opening.starts_at.to_date,
                                       @opening.ends_at.to_date).count).to eql(expected_result)
        end
      end
    end

    describe '#weekly' do

      context "when we have weekly slots" do

        before do
          Timecop.freeze DateTime.current
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          @opening = create :opening_event, :with_booked_opening_slots,
                            starts_at: @starts_at, ends_at: @ends_at,
                            weekly_recurring: true
          create :opening_event, :with_opening_slots,
                 starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end
        after  { Timecop.return }

        it "should find all weekly slots" do
          expect(Slot.all.count).to eql(6)
          expect(Slot.weekly.count).to eql(3)
        end

        it "should generate correct sql query" do
          expected_result = "SELECT \"slots\".* FROM \"slots\" WHERE "\
                            "\"slots\".\"is_weekly\" = 1"
          expect(Slot.weekly.to_sql).to eql(expected_result)
        end
      end

      context "when we don't have weekly slots" do

        before do
          create :opening_event, :with_opening_slots,
                 starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end

        it "should find 0 records" do
          expected_result = 0
          expect(Slot.all.count).to eql(3)
          expect(Slot.weekly.count).to eql(expected_result)
        end
      end
    end

    describe '#not_weekly' do

      context "when we have not weekly slots" do

        before do
          Timecop.freeze DateTime.current
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          @opening = create :opening_event, :with_booked_opening_slots,
                            starts_at: @starts_at, ends_at: @ends_at,
                            weekly_recurring: true
          create :opening_event, :with_opening_slots,
                 starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end
        after  { Timecop.return }

        it "should find all not weekly slots" do
          expect(Slot.all.count).to eql(6)
          expect(Slot.not_weekly.count).to eql(3)
        end

        it "should generate correct sql query" do
          expected_result = "SELECT \"slots\".* FROM \"slots\" WHERE "\
                            "\"slots\".\"is_weekly\" = 0"
          expect(Slot.not_weekly.to_sql).to eql(expected_result)
        end
      end

      context "when we don't have not weekly slots" do

        before do
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          @opening = create :opening_event, :with_booked_opening_slots,
                            starts_at: @starts_at, ends_at: @ends_at,
                            weekly_recurring: true
        end

        it "should find 0 records" do
          expected_result = 0
          expect(Slot.all.count).to eql(3)
          expect(Slot.not_weekly.count).to eql(expected_result)
        end
      end
    end

    describe '#by_week_day' do

      context "when we have slots with current week day" do

        before do
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          @opening = create :opening_event, :with_booked_opening_slots,
                            starts_at: @starts_at, ends_at: @ends_at,
                            weekly_recurring: true
          create :opening_event, :with_opening_slots,
                 starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end

        it "should find all not weekly slots" do
          expect(Slot.all.count).to eql(6)
          expect(Slot.by_week_day(@opening.starts_at.wday).count).to eql(3)
        end

        it "should generate correct sql query" do
          expected_result = "SELECT \"slots\".* FROM \"slots\" WHERE "\
                            "(day_of_the_week = #{@opening.starts_at.wday})"
          expect(Slot.by_week_day(@opening.starts_at.wday).to_sql).to eql(expected_result)
        end
      end

      context "when we don't have slots with current week day" do

        before do
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          create :opening_event, :with_opening_slots,
                 starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
        end

        it "should find 0 records" do
          expected_result = 0
          expect(Slot.all.count).to eql(3)
          expect(Slot.by_week_day(@starts_at.wday).count).to eql(expected_result)
        end
      end
    end

  end

  describe 'class methods' do

    describe '#available_slots_for(event)' do

      context "when we have regular slots for event" do

        before do
          create :opening_event, :with_opening_slots
          create :opening_event, :with_opening_slots,
                 starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)
          @event = create :appointment_event
        end

        it "should find regular slots for event" do
          expect(Slot.all.count).to eql(6)
          expect(Slot.available_slots_for(@event).count).to eql(3)
        end
      end

      context "when we don't have regular slots for event" do

        before do
          create :opening_event, :with_opening_slots,
                 starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)

          @event = build :appointment_event
        end

        it "should find 0 records" do
          expected_result = 0
          expect(Slot.all.count).to eql(3)
          expect(Slot.available_slots_for(@event).count).to eql(expected_result)
        end
      end
    end

    describe '#find_weekly_slots' do

      context "when we have weekly slots with specified time" do

        before do
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          @opening = create :opening_event, :with_booked_opening_slots,
                            starts_at: @starts_at, ends_at: @ends_at,
                            weekly_recurring: true
          create :opening_event, :with_opening_slots,
                 starts_at: (DateTime.now.beginning_of_hour - 2.day),
                 ends_at: (DateTime.now.beginning_of_hour - 1.day)


          @event = create :appointment_event
        end

        it "should find weekly slots for specified time and day of the week" do
          expect(Slot.all.count).to eql(6)
          expect(Slot.find_weekly_slots(@event.starts_at_time,
                                        @event.ends_at_time,
                                        @event.day_of_the_week).count).to eql(2)
        end

        it "should generate correct sql query" do
          expected_result = "SELECT \"slots\".* FROM \"slots\" WHERE \"slots\".\"is_weekly\" "\
                            "= 1 AND (day_of_the_week = #{@event.day_of_the_week}) AND "\
                            "(begins_at_time >= #{@event.starts_at_time} AND "\
                            "(begins_at_time + 1800) <= #{@event.ends_at_time})"

          expect(Slot.find_weekly_slots(@event.starts_at_time,
                                        @event.ends_at_time,
                                        @event.day_of_the_week).to_sql).to eql(expected_result)
        end
      end

      context "when we don't have weekly slots with specified time" do

        before do
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          @opening = create :opening_event, :with_booked_opening_slots,
                            starts_at: @starts_at, ends_at: @ends_at,
                            weekly_recurring: false
          @event = build :appointment_event
        end

        it "should find 0 records" do
          expected_result = 0
          expect(Slot.all.count).to eql(3)
          expect(Slot.find_weekly_slots(@event.starts_at_time,
                                        @event.ends_at_time,
                                        @event.day_of_the_week).count).to eql(expected_result)
        end
      end
    end

    describe '#available_weekly_slots' do

      context "when we have available weekly slots" do

        before do
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          @opening = create :opening_event, :with_booked_opening_slots,
                            starts_at: @starts_at, ends_at: @ends_at,
                            weekly_recurring: true


          @starts_at_two = @starts_at + 1.day
          @ends_at_two = @ends_at + 1.day
          create :opening_event, :with_opening_slots,
                 starts_at: @starts_at_two, ends_at: @ends_at_two,
                 weekly_recurring: false
        end

        it "should find weekly available weekly slots specified date range" do
          expect(Slot.all.count).to eql(6)
          expect(Slot.available_weekly_slots(@starts_at.to_date,
                                             @ends_at_two.to_date).count).to eql(3)
        end
      end

      context "when we don't have available weekly slots" do

        before do
          @starts_at = DateTime.now.beginning_of_hour + 9.hours
          @ends_at = DateTime.now.beginning_of_hour + 9.hours + 30.minutes
          @opening = create :opening_event, :with_booked_opening_slots,
                            starts_at: @starts_at, ends_at: @ends_at,
                            weekly_recurring: false
        end

        it "should find 0 records" do
          expected_result = 0
          expect(Slot.all.count).to eql(3)
          expect(Slot.available_weekly_slots(@starts_at.to_date,
                                             @ends_at.to_date).count).to eql(expected_result)
        end
      end

    end

    describe '#possible_slots_amount_in' do

      before do
        @event = create :opening_event, :with_booked_opening_slots
      end

      it "should calculate how many slots will fit to date range" do
        expected_result = 3.0
        expect(Slot.possible_slots_amount_in(@event.date_range)).to eql(expected_result)
      end
    end
  end

  describe 'instance methods' do

    before do
      @slot = build :opening_slot,
                    begins_at_time: DateTime.parse("2020-08-04 09:30")
                                        .seconds_since_midnight.to_i,
                    is_weekly: false
    end

    describe '#begins_at_hours' do

      it "should return formatted begins_at" do
        expected_result = "09:30"
        expect(@slot.begins_at_hours).to eql(expected_result)
      end
    end

    describe '#ends_at_time' do

      it "should return correct time" do
        expected_result = 36000
        expect(@slot.ends_at_time).to eql(expected_result)
      end
    end

    describe '#is_regular?' do

      it "should return true if slot is not weekly" do
        expected_result = true
        expect(@slot.is_regular?).to eql(expected_result)
      end
    end
  end

end
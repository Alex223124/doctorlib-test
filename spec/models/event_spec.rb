require 'rails_helper'
require "pry"

RSpec.describe Event, type: :model do

  describe 'associations' do

    it { should have_many(:opening_slots).class_name('Slot') }
    it { should have_many(:appointment_slots).class_name('AppointmentSlot') }
    it { should have_many(:booked_slots).class_name('Slot') }
  end

  describe 'validations' do

    it { should validate_presence_of(:starts_at) }
    it { should validate_presence_of(:ends_at) }
    it { should validate_presence_of(:kind) }

    describe '#validates :kind' do

      context "opening" do

        let(:event) { create :opening_event, :with_opening_slots }

        it "should be valid" do
          expect(event).to be_valid
          expect(event.errors).to be_empty
        end
      end

      context "appointment" do

        let(:event) { create :appointment_event, :with_regular_opening_event }

        it "should be valid" do
          expect(event).to be_valid
          expect(event.errors).to be_empty
        end
      end

      context "when kind is not correct" do

        let(:event) { build :appointment_event, :with_regular_opening_event, kind: 'not_correct_kind' }

        it "should not be valid" do
          expect(event).not_to be_valid
        end

        it "should contain correct error" do
          event.valid?
          expect(event.errors).to have_key(:kind)
          expected_message = ["not_correct_kind is not valid. Should be one: opening OR appointment"]
          expect(event.errors[:kind]).to eql(expected_message)
        end
      end
    end

    describe '#validates_with Validators::Event::DateRange' do

      context "when we have opening event" do

        context "when we have correct daterange" do

          let(:event) { build :opening_event, :with_opening_slots }

          it "should not contain errors" do
            event.validates_with(Validators::Event::DateRange)
            expect(event.errors.any?).to be(false)
          end
        end

        context "when we don't have correct daterange" do

          invalid_time = DateTime.now.beginning_of_hour + 10.minutes + 10.seconds
          let(:event) { build :opening_event, :with_opening_slots,
                              starts_at: invalid_time, ends_at: invalid_time }

          it "should contain error" do
            event.validates_with(Validators::Event::DateRange)
            expect(event.errors).to have_key(:date_range)
            expected_message = "Date range (from 'start_at' to 'ends_at') "\
                             "should consist of pieces 30 minutes each"
            expect(event.errors[:date_range][0]).to eql(expected_message)
          end
        end
      end
    end

    describe '#validates_with Validators::Event::ConflictingSlots' do

      context "when we have opening event" do

        context "when we don't have conflicting slots" do

          let(:event) { build :opening_event, :with_opening_slots }

          it "should not contain errors" do
            event.validates_with(Validators::Event::ConflictingSlots)
            expect(event.errors.any?).to be(false)
          end
        end

        context "when we have conflicting slots" do

          let!(:first_event) { create :opening_event, :with_opening_slots }
          let(:second_event) { build :opening_event, :with_opening_slots }

          it "should contain error" do
            second_event.validates_with(Validators::Event::ConflictingSlots)
            expect(second_event.errors).to have_key(:conflicting_slots)
            expected_message = "You can't create event. Please pick another 'start_at' end"\
                             "'ends_at' during opening creation + weekly mark."
            expect(second_event.errors[:conflicting_slots][0]).to eql(expected_message)
          end
        end
      end
    end

    describe '#validates_with Validators::Event::SlotsPresence' do

      context "when we have appointment event" do

        context "when have necessary slots" do

          let(:event) { build :appointment_event, :with_regular_opening_event }

          it "should not contain errors" do
            event.validates_with(Validators::Event::ConflictingSlots)
            expect(event.errors.any?).to be(false)
          end
        end

        context "when we don't have necessary slots" do

          let(:event) { build :appointment_event }

          it "should contain error" do
            event.validates_with(Validators::Event::SlotsPresence)
            expect(event.errors).to have_key(:slots_presence)
            expected_message = "Date range (from 'start_at' to 'ends_at') you specified for the appointment is not valid. "\
                             "Please pick 'start_at' to 'ends_at' which fits available slots."
            expect(event.errors[:slots_presence][0]).to eql(expected_message)
          end
        end
      end
    end
  end

  describe 'class methods' do

    describe '#availabilities' do

      context "when we have slots for availabilities" do

        let!(:event) { create :appointment_event, :with_weekly_opening_event }

        it "should return availabilities in correct format" do
          current_hour = DateTime.now.beginning_of_hour
          starts_at = current_hour + 9.hours
          availabilities = Event.availabilities(starts_at)
          expected_result = [{:date=>"#{starts_at.strftime("%Y-%m-%d")}", :slots=>[]},
                             {:date=>"#{(starts_at + 1.day).strftime("%Y-%m-%d")}", :slots=>[]},
                             {:date=>"#{(starts_at + 2.day).strftime("%Y-%m-%d")}", :slots=>[]},
                             {:date=>"#{(starts_at + 3.day).strftime("%Y-%m-%d")}", :slots=>[]},
                             {:date=>"#{(starts_at + 4.day).strftime("%Y-%m-%d")}", :slots=>[]},
                             {:date=>"#{(starts_at + 5.day).strftime("%Y-%m-%d")}", :slots=>[]},
                             {:date=>"#{(starts_at + 6.day).strftime("%Y-%m-%d")}",
                              :slots=>["#{(current_hour + 6.hours).strftime("%H:%M")}",
                                       "#{(current_hour + 6.hours + 30.minutes).strftime("%H:%M")}",
                                       "#{(current_hour + 7.hours).strftime("%H:%M")}"]}]
          expect(availabilities).to eql(expected_result)
        end
      end

      context "when we don't have slots for availabilities" do

        it "should return 0 availabilities in correct format" do
          current_hour = DateTime.now.beginning_of_hour
          starts_at = current_hour + 9.hours
          availabilities = Event.availabilities(starts_at)
          expected_result = [{:date=>"#{starts_at.strftime("%Y-%m-%d")}", :slots=>[]},
                             {:date=>"#{(starts_at + 1.day).strftime("%Y-%m-%d")}", :slots=>[]},
                             {:date=>"#{(starts_at + 2.day).strftime("%Y-%m-%d")}", :slots=>[]},
                             {:date=>"#{(starts_at + 3.day).strftime("%Y-%m-%d")}", :slots=>[]},
                             {:date=>"#{(starts_at + 4.day).strftime("%Y-%m-%d")}", :slots=>[]},
                             {:date=>"#{(starts_at + 5.day).strftime("%Y-%m-%d")}", :slots=>[]},
                             {:date=>"#{(starts_at + 6.day).strftime("%Y-%m-%d")}", :slots=>[]}]
          expect(availabilities).to eql(expected_result)
        end
      end

      context "when starts_at is less than current date and time" do

        it "should return nil" do
          starts_at = DateTime.now.beginning_of_hour - 1.day
          availabilities = Event.availabilities(starts_at)
          expected_result = nil
          expect(availabilities).to eql(expected_result)
        end
      end
    end
  end

  describe 'instance methods' do

    describe '#is_opening?' do

      context "when we have opening event" do

        let(:event) { create :opening_event, :with_opening_slots }

        it "should return true" do
          expect(event.is_opening?).to be(true)
        end
      end

      context "when we have appointment event" do

        let(:event) { create :appointment_event, :with_regular_opening_event }

        it "should return false" do
          expect(event.is_opening?).to be(false)
        end
      end
    end

    describe '#is_appointment?' do

      context "when we have opening event" do

        let(:event) { create :opening_event, :with_opening_slots }

        it "should return false" do
          expect(event.is_appointment?).to be(false)
        end
      end

      context "when we have appointment event" do

        let(:event) { create :appointment_event, :with_regular_opening_event }

        it "should return true" do
          expect(event.is_appointment?).to be(true)
        end
      end
    end

    describe '#is_weekly?' do

      context "when we have weekly event" do

        let(:event) { create :opening_event, :with_opening_slots, weekly_recurring: true }

        it "should return false" do
          expect(event.is_weekly?).to be(true)
        end
      end

      context "when we have regular event" do

        let(:event) { create :opening_event, :with_opening_slots }

        it "should return true" do
          expect(event.is_weekly?).to be(false)
        end
      end
    end

    describe '#day_of_the_week' do

      let(:event) { create :opening_event, :with_opening_slots,
                           starts_at: DateTime.parse("2014-08-04 09:30"),
                           ends_at: DateTime.parse("2014-08-04 12:30")}

      it "should return correct numerical representation of day of the week" do
        expected_result = 1
        expect(event.day_of_the_week).to be(expected_result)
      end
    end

    describe '#starts_at_time' do

      let(:event) { create :opening_event, :with_opening_slots,
                           starts_at: DateTime.parse("2014-08-04 09:30"),
                           ends_at: DateTime.parse("2014-08-04 12:30")}

      it "should return starts_at in seconds" do
        expected_result = 34200
        expect(event.starts_at_time).to be(expected_result)
      end
    end

    describe '#ends_at_time' do

      let(:event) { create :opening_event, :with_opening_slots,
                           starts_at: DateTime.parse("2014-08-04 09:30"),
                           ends_at: DateTime.parse("2014-08-04 12:30")}

      it "should return starts_at in seconds" do
        expected_result = 45000
        expect(event.ends_at_time).to be(expected_result)
      end
    end
  end

  context "tests from task description" do

    it "should be green" do
      create_event = Services::Events::Create.new(kind: 'opening',
                                                  starts_at: DateTime.parse("2020-08-04 09:30"),
                                                  ends_at: DateTime.parse("2020-08-04 12:30"),
                                                  weekly_recurring: true)
      create_event.call

      create_event = Services::Events::Create.new(kind: 'appointment',
                                                  starts_at: DateTime.parse("2020-08-11 10:30"),
                                                  ends_at: DateTime.parse("2020-08-11 11:30"))
      create_event.call

      availabilities = Event.availabilities DateTime.parse("2020-08-10")
      assert_equal '2020-08-10', availabilities[0][:date]
      assert_equal [], availabilities[0][:slots]
      assert_equal '2020-08-11', availabilities[1][:date]
      assert_equal ["09:30", "10:00", "11:30", "12:00"], availabilities[1][:slots]
      assert_equal [], availabilities[2][:slots]
      assert_equal '2020-08-16', availabilities[6][:date]
      assert_equal 7, availabilities.length
    end
  end
end
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Schedule do
  let(:schedule) { FactoryBot.create(:schedule) }
  let(:first_reservation_time) { Time.zone.parse("#{Date.today} 10:00:00") + 1.day }

  context "single instrument on schedule" do
    let(:instrument) { FactoryBot.create(:setup_instrument) }

    it "should have a schedule" do
      expect(instrument.schedule).to be
    end

    it "should be the only product on the schedule" do
      expect(instrument.schedule.products).to eq([instrument])
    end

    context "with a reservation placed" do
      let!(:reservation) do
        FactoryBot.create(:purchased_reservation,
                          product: instrument,
                          reserve_start_at: first_reservation_time,
                          reserve_end_at: first_reservation_time + 1.hour)
      end

      it "should not allow a second reservation that overlaps" do
        reservation2 = FactoryBot.build(:setup_reservation,
                                        product: instrument,
                                        reserve_start_at: first_reservation_time + 30.minutes,
                                        reserve_end_at: first_reservation_time + 1.hour + 30.minutes)
        expect(reservation2).not_to be_valid
      end

      it "should allow a second reservation that doesn't overlap" do
        reservation2 = FactoryBot.build(:setup_reservation,
                                        product: instrument,
                                        reserve_start_at: first_reservation_time + 1.hour,
                                        reserve_end_at: first_reservation_time + 2.hours)
        expect(reservation2).to be_valid
      end
    end
  end

  context "two instruments on a schedule" do
    let(:instruments) { FactoryBot.create_list(:setup_instrument, 2, schedule:) }

    context "with a reservation placed" do
      let!(:reservation) do
        FactoryBot.create(:purchased_reservation,
                          product: instruments[0],
                          reserve_start_at: first_reservation_time,
                          reserve_end_at: first_reservation_time + 1.hour)
      end

      it "should not allow a second reservation that overlaps on the other instrument" do
        reservation2 = FactoryBot.build(:setup_reservation,
                                        product: instruments[1],
                                        reserve_start_at: first_reservation_time + 30.minutes,
                                        reserve_end_at: first_reservation_time + 1.hour + 30.minutes)
        expect(reservation2).not_to be_valid
      end

      context "a second reservation successfully placed" do
        let!(:reservation2) do
          FactoryBot.create(:purchased_reservation,
                            product: instruments[1],
                            reserve_start_at: first_reservation_time + 1.hour,
                            reserve_end_at: first_reservation_time + 2.hours)
        end

        it "should have the reservations under the individual instruments" do
          expect(instruments[0].reservations).to eq([reservation])
          expect(instruments[1].reservations).to eq([reservation2])
        end

        it "should have both reservations under the schedule" do
          expect(schedule.reservations).to eq([reservation, reservation2])
        end
      end
    end
  end

  describe "active scope" do
    let(:facility) { FactoryBot.create(:setup_facility) }
    let!(:instrument) { FactoryBot.create(:setup_instrument, facility:) }
    let!(:archived_instrument) { FactoryBot.create(:setup_instrument, facility:, is_archived: true) }

    it "should include non-archived schedule" do
      expect(Schedule.active).to include instrument.schedule
    end

    it "should not include the archived schedule" do
      expect(Schedule.active).not_to include archived_instrument.schedule
    end
  end
end

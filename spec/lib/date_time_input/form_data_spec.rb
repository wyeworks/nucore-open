# frozen_string_literal: true

require "rails_helper"

RSpec.describe DateTimeInput::FormData do

  describe ".from_param" do
    let(:form_data) { described_class.from_param(hash) }
    subject(:output_time) { form_data.to_time }

    describe "with only a date" do
      let(:hash) { { date: "04/06/2017" } }
      it { is_expected.to eq(Time.zone.parse("2017-04-06")) }
    end

    describe "with all the fields in the AM" do
      let(:hash) { { date: "04/06/2017", hour: 4, minute: 19, ampm: "AM" } }
      it { is_expected.to eq(Time.zone.parse("2017-04-06 04:19").in_time_zone) }
    end

    describe "with all the fields in the PM" do
      let(:hash) { { date: "04/06/2017", hour: 4, minute: 19, ampm: "PM" } }
      it { is_expected.to eq(Time.zone.parse("2017-04-06 16:19").in_time_zone) }
    end

    describe "missing data" do
      let(:hash) { { date: "04/06/2017", hour: 4 } }
      it { is_expected.to be_nil }
    end

    describe "an invalid date" do
      let(:hash) { { date: "19/06/2017", hour: 4, minute: 19, ampm: "PM" } }
      it { is_expected.to be_nil }
    end

    describe "with an ISO date" do
      let(:hash) { { date: "2017-04-06", hour: 4, minute: 19, ampm: "PM" } }
      it { is_expected.to eq(Time.zone.parse("2017-04-06 16:19").in_time_zone) }
    end
  end

  describe ".from_param!" do
    let(:form_data) { described_class.from_param!(hash) }
    subject(:output_time) { form_data.to_time }

    describe "with only a date" do
      let(:hash) { { date: "04/06/2017" } }
      it { is_expected.to eq(Time.zone.parse("2017-04-06")) }
    end

    describe "with all the fields in the AM" do
      let(:hash) { { date: "04/06/2017", hour: 4, minute: 19, ampm: "AM" } }
      it { is_expected.to eq(Time.zone.parse("2017-04-06 04:19").in_time_zone) }
    end

    describe "with all the fields in the PM" do
      let(:hash) { { date: "04/06/2017", hour: 4, minute: 19, ampm: "PM" } }
      it { is_expected.to eq(Time.zone.parse("2017-04-06 16:19").in_time_zone) }
    end

    describe "missing data" do
      let(:hash) { { date: "04/06/2017", hour: 4 } }
      specify { expect { subject }.to raise_error(ArgumentError, /Must have all or none/) }
    end
  end

  describe "with a datetime" do
    let(:time) { Time.zone.parse("2017-04-11 17:34") }
    subject(:form_data) { described_class.new(time) }

    describe "fields" do
      specify { expect(form_data.date).to eq(Date.new(2017, 4, 11)) }
      specify { expect(form_data.hour).to eq(5) }
      specify { expect(form_data.minute).to eq(34) }
      specify { expect(form_data.ampm).to eq("PM") }
      specify { expect(form_data.to_time).to eq(time) }
    end

    describe "to_h" do
      it "outputs the expected hash" do
        expect(form_data.to_h).to eq(
          date: Date.new(2017, 4, 11),
          hour: 5,
          minute: 34,
          ampm: "PM",
        )
      end
    end
  end

  describe "with a null value" do
    subject(:form_data) { described_class.new(nil) }

    describe "fields" do
      specify { expect(form_data.date).to be_nil }
      specify { expect(form_data.hour).to be_nil }
      specify { expect(form_data.minute).to be_nil }
      specify { expect(form_data.ampm).to be_nil }
    end

    describe "to_h" do
      it "renders null values" do
        expect(form_data.to_h).to eq(
          date: nil,
          hour: nil,
          minute: nil,
          ampm: nil,
        )
      end
    end
  end

end

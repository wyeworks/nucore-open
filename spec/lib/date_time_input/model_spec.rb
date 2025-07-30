# frozen_string_literal: true

require "rails_helper"

RSpec.describe DateTimeInput::Model do

  # Super won't work within the same class, so create a basic superclass.
  let(:ar_faker_clazz) do
    Class.new do
      attr_accessor :datetime
    end
  end

  let(:clazz) do
    Class.new(ar_faker_clazz) do
      include DateTimeInput::Model

      date_time_inputable :datetime
    end
  end

  subject(:instance) { clazz.new }

  describe "setter" do
    it "can set a datetime directly" do
      date = Time.current
      instance.datetime = date
      expect(instance.datetime).to eq(date)
    end

    it "can set from a valid set of fields" do
      params = { date: "06/09/2017", hour: "6", minute: "07", ampm: "PM" }
      instance.datetime = params
      expect(instance.datetime).to eq(Time.zone.parse("2017-06-09 18:07"))
    end

    it "sets to nil on invalid fields" do
      params = { date: "06/09/2017", hour: "6" }
      instance.datetime = params
      expect(instance.datetime).to be_nil
    end
  end

  describe "getter" do
    describe "with a time value" do
      let(:time) { Time.zone.parse("2017-08-03 14:23:45") }
      subject(:data) { instance.tap { |i| i.datetime = time }.datetime_date_time_data }

      specify { expect(data.date).to eq("08/03/2017") }
      specify { expect(data.hour).to eq(2) }
      specify { expect(data.minute).to eq(23) }
      specify { expect(data.ampm).to eq("PM") }
    end

    describe "with an empty time value" do
      subject(:data) { instance.datetime_date_time_data }

      specify { expect(data.date).to be_nil }
      specify { expect(data.hour).to be_nil }
      specify { expect(data.minute).to be_nil }
      specify { expect(data.ampm).to be_nil }
    end
  end
end

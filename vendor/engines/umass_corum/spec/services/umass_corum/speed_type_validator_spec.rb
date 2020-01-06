# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::SpeedTypeValidator do
  it "raises a format error if it's not a valid format" do
    expect { described_class.new("INVALID").account_is_open! }.to raise_error(ValidatorError)
  end

  let(:speed_type) { "847564" }
  let(:validator) { described_class.new(speed_type) }

  it "returns successfully if the chart string exists in the DB" do
    create(:api_speed_type, speed_type: speed_type)
    validator.account_is_open!
  end

  it "raises an error if the chart string does not exist in the DB" do
    expect { validator.account_is_open! }.to raise_error(ValidatorError, /It should have been fetched from the API/)
  end

  it "raises an error if the entry in the DB is expired" do
    create(:api_speed_type, :expired, speed_type: speed_type)
    expect { validator.account_is_open! }.to raise_error(ValidatorError, /expired/)
  end

  it "doesn't care when what date if it's active" do
    create(:api_speed_type, speed_type: speed_type)
    validator.account_is_open!(3.days.ago)
    validator.account_is_open!(3.days.from_now)
    validator.account_is_open!(2.years.ago)
  end

  it "has a generic message if there is no error in the table" do
    create(:api_speed_type, :expired, speed_type: speed_type, error_desc: "")
    expect { validator.account_is_open! }.to raise_error(ValidatorError, /not legal at the time/)
  end
end

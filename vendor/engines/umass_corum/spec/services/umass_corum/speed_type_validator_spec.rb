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

  context "when the entry in the DB is expired" do
    before { create(:api_speed_type, :expired, speed_type: speed_type, date_removed: 1.week.ago) }

    it "raises an error if the date passed in is after the expiration date" do
      expect { validator.account_is_open!(Time.current) }.to raise_error(ValidatorError, /expired/)
    end

    it "raises an error if the date passed in is before the date_added" do
      expect { validator.account_is_open!(2.years.ago) }.to raise_error(ValidatorError, /expired/)
    end

    it "is valid if the date passed in is between the date_added and the expiration date" do
      expect(validator.account_is_open!(3.months.ago)).to be_truthy
    end

    context "when the account is suspended" do
      before { create(:speed_type_account, :with_account_owner, account_number: speed_type, suspended_at: 1.week.ago) }

      it "raises a suspended account error error if the fulfillment date is after suspended_at" do
        expect { validator.account_is_open! }.to raise_error(ValidatorError, /suspended/)
      end

      it "does not raise a suspended account error if the fulfillment date is before suspended_at" do
        expect(validator.account_is_open!(3.months.ago)).to be_truthy
      end
    end
  end

  context "when the entry in the DB is active (not expired)" do
    before { create(:api_speed_type, speed_type: speed_type, date_added: 1.month.ago) }

    it "raises an error if the date passed in is before the date_added" do
      expect { validator.account_is_open!(2.months.ago) }.to raise_error(ValidatorError, /not legal at the time of fulfillment/)
    end

    it "is valid if the date passed in is after the date_added" do
      expect(validator.account_is_open!(3.days.from_now)).to be_truthy
    end

    context "when the account is suspended" do
      before { create(:speed_type_account, :with_account_owner, account_number: speed_type, suspended_at: 1.week.ago) }

      it "raises a suspended account error error if the fulfillment date is after suspended_at" do
        expect { validator.account_is_open! }.to raise_error(ValidatorError, /suspended/)
      end

      it "does not raise a suspended account error if the fulfillment date is before suspended_at" do
        expect { validator.account_is_open!(2.months.ago) }.to raise_error(ValidatorError, /not legal at the time of fulfillment/)
      end
    end
  end

  it "has a generic message if there is no error in the table" do
    create(:api_speed_type, :expired, speed_type: speed_type, error_desc: "")
    expect { validator.account_is_open! }.to raise_error(ValidatorError, /not legal at the time/)
  end
end

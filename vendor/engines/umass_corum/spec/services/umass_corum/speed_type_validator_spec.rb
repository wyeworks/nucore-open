# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::SpeedTypeValidator do
  it "raises a format error if it's not a valid format" do
    expect { described_class.new("INVALID").account_is_open! }.to raise_error(AccountValidator::ValidatorError)
  end

  let(:speed_type) { "847564" }
  let(:validator) { described_class.new(speed_type) }
  let(:date_added) { Time.now - 1.year }
  let(:project_start_date) { 1.month.ago }
  let(:project_end_date) { 1.month.from_now }

  it "returns successfully if the chart string exists in the DB" do
    create(:api_speed_type, speed_type: speed_type, project_start_date: project_start_date, project_end_date: project_end_date)
    validator.account_is_open!
  end

  it "raises an error if the chart string does not exist in the DB" do
    expect { validator.account_is_open! }.to raise_error(AccountValidator::ValidatorError, /It should have been fetched from the API/)
  end

  context "when the entry in the DB is expired" do
    before { create(:api_speed_type, :expired, speed_type: speed_type, date_removed: 1.week.ago, project_id: nil) }

    it "raises an error if the date passed in is after the expiration date" do
      expect { validator.account_is_open!(Time.current) }.to raise_error(AccountValidator::ValidatorError, /expired/)
    end

    it "raises an error if the date passed in is before the date_added" do
      expect { validator.account_is_open!(2.years.ago) }.to raise_error(AccountValidator::ValidatorError, /expired/)
    end

    it "is valid if the date passed in is between the date_added and the expiration date" do
      expect(validator.account_is_open!(3.months.ago)).to be_truthy
    end

    context "when the account is suspended" do
      before { create(:speed_type_account, :with_account_owner, account_number: speed_type, suspended_at: 1.week.ago) }

      it "raises a suspended account error error if the fulfillment date is after suspended_at" do
        expect { validator.account_is_open! }.to raise_error(AccountValidator::ValidatorError, /suspended/)
      end

      it "does not raise a suspended account error if the fulfillment date is before suspended_at" do
        expect(validator.account_is_open!(3.months.ago)).to be_truthy
      end
    end
  end

  context "when the entry in the DB is active (not expired) and there is no project_id" do
    before { create(:api_speed_type, speed_type: speed_type, date_added: 1.month.ago, project_id: nil) }

    it "raises an error if the date passed in is before the date_added" do
      expect { validator.account_is_open!(2.months.ago) }.to raise_error(AccountValidator::ValidatorError, /not legal at the time of fulfillment/)
    end

    it "is valid if the date passed in is after the date_added" do
      expect(validator.account_is_open!(3.days.from_now)).to be_truthy
    end

    context "when the account is suspended" do
      before { create(:speed_type_account, :with_account_owner, account_number: speed_type, suspended_at: 1.week.ago) }

      it "raises a suspended account error error if the fulfillment date is after suspended_at" do
        expect { validator.account_is_open! }.to raise_error(AccountValidator::ValidatorError, /suspended/)
      end

      it "does not raise a suspended account error if the fulfillment date is before suspended_at" do
        expect { validator.account_is_open!(2.months.ago) }.to raise_error(AccountValidator::ValidatorError, /not legal at the time of fulfillment/)
      end
    end
  end

  context "when the entry in the DB is active (not expired) and there is project_id" do
    it "raises an error if the date passed is not between the project dates" do
      create(:api_speed_type, speed_type: speed_type, date_added: 1.year.ago, project_start_date: 1.year.ago, project_end_date: 1.year.ago)
      expect { validator.account_is_open!(Time.current) }.to raise_error(AccountValidator::ValidatorError, /Was not legal at the time of fulfillment/)
    end

    it "is valid if the date passed is between the project dates" do
      create(:api_speed_type, speed_type: speed_type, date_added: 1.year.ago, project_start_date: 1.year.ago, project_end_date: 1.year.from_now)
      expect(validator.account_is_open!(3.days.from_now)).to be_truthy
    end

    it "raises an error if it has no project_start_date" do
      create(:api_speed_type, :not_valid_start_date, speed_type: speed_type)
      expect { validator.account_is_open!(Time.current) }.to raise_error(AccountValidator::ValidatorError, /Both project start and end dates are required for validation/)
    end

    it "raises an error if it has no project_end_date" do
      create(:api_speed_type, :not_valid_end_date, speed_type: speed_type)
      expect { validator.account_is_open!(Time.current) }.to raise_error(AccountValidator::ValidatorError, /Both project start and end dates are required for validation/)
    end
  end

  describe "#valid_at?" do
    context "when there is a project_id" do
      let!(:api_speed_type) { create(:api_speed_type, speed_type: speed_type, project_start_date: 4.days.ago, project_end_date: 4.days.from_now) }

      it "returns true for a fulfilled_date at the beginning of the project_start_date day" do
        expect(validator.valid_at?(4.days.ago.beginning_of_day)).to be true
      end

      it "returns true for a fulfilled_date at the end of the project_end_date day" do
        expect(validator.valid_at?(4.days.from_now.end_of_day)).to be true
      end

      it "returns false with fulfilled_date is before the project_start_date" do
        expect(validator.valid_at?(5.days.ago)).to be false
      end

      it "returns false with fulfilled_date is after the project_end_date" do
        expect(validator.valid_at?(5.days.from_now)).to be false
      end
    end

    context "when there is not a project_id and there is a date_removed" do
      let!(:api_speed_type) { create(:api_speed_type, speed_type: speed_type, project_id: nil, date_added: 4.days.ago, date_removed: 4.days.from_now, active: false) }

      it "returns true for a fulfilled_date at the beginning of the date_added day" do
        expect(validator.valid_at?(4.days.ago.beginning_of_day)).to be true
      end

      it "returns true for a fulfilled_date at the end of the date_removed day" do
        expect(validator.valid_at?(4.days.from_now.end_of_day)).to be true
      end

      it "returns false with fulfilled_date is before the date_added" do
        expect(validator.valid_at?(5.days.ago)).to be false
      end

      it "returns false with fulfilled_date is after the date_removed" do
        expect(validator.valid_at?(5.days.from_now)).to be false
      end
    end
  end

  it "checks the date_added_admin_override, when it exists" do
    create(:api_speed_type, speed_type: speed_type, date_added: date_added, date_added_admin_override: date_added - 1.years, project_id: nil)
    expect(validator.account_is_open!(date_added - 1.years + 1.day)).to be true
  end

  it "checks the date_added, when the date_added_admin_override does not exist" do
    create(:api_speed_type, speed_type: speed_type, date_added: date_added)
    expect { validator.account_is_open!(date_added - 1.year + 1.day) }.to raise_error(AccountValidator::ValidatorError)
  end

  it "has a generic message if there is no error in the table" do
    create(:api_speed_type, :expired, speed_type: speed_type, error_desc: "", project_id: nil)
    expect { validator.account_is_open! }.to raise_error(AccountValidator::ValidatorError, /not legal at the time/)
  end
end

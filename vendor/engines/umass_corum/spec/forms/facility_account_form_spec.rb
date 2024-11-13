# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::FacilityAccountForm do
  let(:facility_account_form) { described_class.new(account_params) }
  let(:facility) { create(:facility) }
  let(:account) { create(:speed_type_account, :with_account_owner) }
  let(:account_params) do
    facility.facility_accounts.new(
      is_active: true,
      revenue_account: Settings.accounts.revenue_account_default,
      account_number: account.account_number,
    )
  end

  it "is valid when the API SpeedType is active" do
    api_speed_type = create(:api_speed_type, speed_type: account.account_number, active: true)

    expect(facility_account_form).to receive(:api_speed_type).twice.and_return(api_speed_type)
    expect(facility_account_form).to be_valid
  end

  it "is NOT valid when the API SpeedType is inactive" do
    api_speed_type = create(:api_speed_type, speed_type: account.account_number, active: false)

    expect(facility_account_form).to receive(:api_speed_type).twice.and_return(api_speed_type)
    expect(facility_account_form).not_to be_valid
    expect(facility_account_form.errors.messages[:base]).to include("AccountValidator::ValidatorError")
  end

end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityUserPermission do
  let(:facility) { create(:facility) }
  let(:user) { create(:user) }

  subject(:permission) { build(:facility_user_permission, user:, facility:) }

  it { is_expected.to be_valid }

  it "enforces uniqueness of user per facility" do
    create(:facility_user_permission, user:, facility:)
    expect(permission).not_to be_valid
    expect(permission.errors[:user_id]).to be_present
  end

  it "allows the same user in different facilities" do
    other_facility = create(:facility)
    create(:facility_user_permission, user:, facility: other_facility)
    expect(permission).to be_valid
  end

  it "defaults all permissions to false" do
    permission.save!
    FacilityUserPermission::PERMISSIONS.each do |perm|
      expect(permission.send(perm)).to be false
    end
  end
end

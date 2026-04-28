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

  it "defaults all permission columns to false at the DB level" do
    permission = FacilityUserPermission.create!(user: create(:user), facility: create(:facility))
    FacilityUserPermission::PERMISSIONS.each do |perm|
      expect(permission.send(perm)).to be false
    end
  end

  describe "read_access validation" do
    it "is invalid when another permission is set without read_access" do
      permission.read_access = false
      permission.billing_send = true
      expect(permission).not_to be_valid
      expect(permission.errors[:read_access]).to be_present
    end

    it "is valid with read_access plus another permission" do
      permission.read_access = true
      permission.billing_send = true
      expect(permission).to be_valid
    end

    it "is valid with only read_access" do
      permission.read_access = true
      expect(permission).to be_valid
    end

    it "is valid with no permissions at all" do
      permission.read_access = false
      expect(permission).to be_valid
    end
  end
end

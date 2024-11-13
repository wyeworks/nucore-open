# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do

  it "requires unique employee id" do
    create(:user, umass_emplid: "id_2")
    is_expected.to validate_uniqueness_of(:umass_emplid)
  end

  it "does not require unique employee id for subsidiary accounts" do
    create(:user, umass_emplid: "id_2")
    subsidiary_user = build(:user, umass_emplid: "id_2", subsidiary_account: true)
    standard_user = build(:user, umass_emplid: "id_2")
    expect(subsidiary_user).to be_valid
    expect(standard_user).not_to be_valid
  end

  it "allows editing standard user when a corresponding subsidiary account exists" do
    standard_user = create(:user, umass_emplid: "id_2")
    subsidiary_user = create(:user, umass_emplid: "id_2", subsidiary_account: true)
    standard_user.email = "admin@nucore.org"
    expect(standard_user).to be_valid
  end

  it "requires unique umass_emplid on update for standard user" do
    create(:user, umass_emplid: "id_2")
    standard_user = create(:user, umass_emplid: nil, subsidiary_account: false)
    standard_user.umass_emplid = "id_2"
    expect(standard_user).not_to be_valid
  end
end

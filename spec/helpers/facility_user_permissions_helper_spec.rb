# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityUserPermissionsHelper do

  describe "sorted_permissions_with_labels" do
    it "puts read_access first and the rest alphabetized by display name" do
      expect(helper.sorted_permissions_with_labels.first).to eq([:read_access, "Read Access"])

      labels = helper.sorted_permissions_with_labels.drop(1).map { |_perm, label| label }
      expect(labels).to eq(labels.sort)
    end
  end

  describe "permission_summary" do
    let(:permission) do
      build(:facility_user_permission, account_management: true, billing_journals: true)
    end

    it "lists Read Access first and the rest alphabetically" do
      expect(helper.permission_summary(permission)).to eq("Read Access, Billing Journals, Payment Source Management")
    end
  end

end

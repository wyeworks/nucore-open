# frozen_string_literal: true

require "rails_helper"

RSpec.describe "creating accounts" do
  let(:admin) { create(:user, :administrator) }
  let(:user) { create(:user) }
  let(:facility_account_type) do
    Account.config.creation_enabled_types.intersection(
      Account.config.facility_account_types
    ).first
  end
  let(:facility_account_class) { facility_account_type.constantize }

  before do
    login_as admin
  end

  context "when facility is cross facility" do
    let(:facility) { Facility.cross_facility }

    describe "per facility account" do
      before do
        skip if facility_account_type.blank?
      end

      context "when it's globally managed" do
        before do
          allow(Account.config)
            .to(receive(:facility_account_globally_managed_types)) do
              [facility_account_type]
            end
        end

        it "can create the account type" do
          get new_facility_account_path(facility, owner_user_id: user.id)

          expect(page).to(
            have_content(facility_account_class.model_name.human)
          )
        end

        it "includes a facility select field" do
          get new_facility_account_path(
            facility, owner_user_id: user.id,
            account_type: facility_account_type,
          )

          expect(page).to have_field(
            "#{facility_account_type.underscore}[facility_ids][]",
          )
        end
      end

      context "when it's not globally managed" do
        before do
          allow(Account.config)
            .to(receive(:facility_account_globally_managed_types)) do
              []
            end
        end

        it "does not show the account type on creation" do
          get new_facility_account_path(facility, owner_user_id: user.id)

          expect(page).to have_content("Add Payment Source")
          expect(page).not_to(
            have_content(facility_account_class.model_name.human)
          )
        end
      end
    end
  end

  context "when facility is not cross facility" do
    let(:facility) { create(:setup_facility) }

    describe "per facility account" do
      before do
        skip if facility_account_type.blank?
      end

      context "when the account is globally managed" do
        before do
          allow(Account.config)
            .to(receive(:facility_account_globally_managed_types)) do
              [facility_account_type]
            end
        end

        it "shows the account type on creation" do
          get new_facility_account_path(facility, owner_user_id: user.id)

          expect(page).to(
            have_content(facility_account_class.model_name.human)
          )
        end

        it "does not show the facilities select field" do
          get new_facility_account_path(facility, owner_user_id: user.id)

          expect(page).to have_content("Add Payment Source")
          expect(page).not_to have_field(
            "#{facility_account_type.underscore}[faiclitie_ids][]"
          )
        end
      end
    end
  end
end

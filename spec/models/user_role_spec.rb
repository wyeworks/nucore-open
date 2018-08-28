# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserRole do
  describe "validations" do
    subject(:user_role) { described_class.new(user: user, role: role, facility: facility) }
    let(:user) { create(:user) }

    context "when the role is Billing Administrator" do
      let(:facility) { nil }
      let(:role) { described_class::BILLING_ADMINISTRATOR }

      context "and the billing_administrator feature is enabled", feature_setting: { billing_administrator: true } do
        it { is_expected.to be_valid }
      end

      context "and the billing_administrator feature is disabled", feature_setting: { billing_administrator: false } do
        it "is invalid" do
          is_expected.not_to be_valid
          expect(user_role.errors[:role])
            .to include(a_string_matching("is not a valid value"))
        end
      end
    end

    context "when given a nonexistent role" do
      let(:role) { "NOT A VALID ROLE" }
      let(:facility) { nil }

      it "requires a valid role" do
        is_expected.not_to be_valid
        expect(user_role.errors[:role])
          .to include(a_string_matching("not a valid value"))
      end
    end

    context "when given a facility-specific role" do
      let(:role) { described_class::FACILITY_STAFF }

      context "and facility is nil" do
        let(:facility) { nil }

        it "requires a facility" do
          is_expected.not_to be_valid
          expect(user_role.errors[:role])
            .to include(a_string_matching("must be associated with a facility"))
        end
      end

      context "and facility is 'all' (cross-facility)" do
        let(:facility) { Facility.cross_facility }

        it "requires a single facility" do
          is_expected.not_to be_valid
          expect(user_role.errors[:role])
            .to include(a_string_matching("must be associated with a facility"))
        end
      end

      context "and given a facility" do
        let(:facility) { create(:facility) }

        it { is_expected.to be_valid }
      end
    end

    context "when given a non-facility-specific (global) role" do
      let(:role) { described_class::ADMINISTRATOR }

      context "and facility is nil" do
        let(:facility) { nil }

        it { is_expected.to be_valid }
      end

      context "and facility is 'all' (cross-facility)" do
        let(:facility) { Facility.cross_facility }

        it { is_expected.to be_valid }
      end

      context "and given a facility" do
        let(:facility) { create(:facility) }

        it "requires there to be no facility" do
          is_expected.not_to be_valid
          expect(user_role.errors[:role])
            .to include(a_string_matching("may not have a facility"))
        end
      end
    end

    context "when a user has an existing role" do
      let(:facility) { create(:facility) }
      let(:user) { create(:user, :staff, facility: facility) }

      context "when adding a duplicate role" do
        let(:role) { user.user_roles.first.role }

        it "is invalid" do
          is_expected.not_to be_valid
          expect(user_role.errors[:role])
            .to include(a_string_matching("already has this role"))
        end
      end

      context "when adding a different role" do
        let(:role) { described_class::FACILITY_DIRECTOR }

        it { is_expected.to be_valid }
      end
    end
  end

  describe "#in?" do
    subject(:user_role) { described_class.new(role: "Facility Manager") }

    describe "a single symbol" do
      it { is_expected.to be_in(:facility_manager) }
      it { is_expected.not_to be_in(:administrator) }
    end

    describe "a lower case string" do
      it { is_expected.to be_in("facility_manager") }
      it { is_expected.not_to be_in("administrator") }
    end

    describe "upper case strings" do
      it { is_expected.to be_in(["Administrator", "Facility Manager"]) }
      it { is_expected.not_to be_in(["Administrator", "Facility Staff"]) }
    end

    describe "an array of mixed" do
      it { is_expected.to be_in(["Administrator", :facility_manager]) }
      it { is_expected.to be_in([:administrator, "Facility Manager"]) }
    end
  end
end

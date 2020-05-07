# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserRole do
  describe "validations" do
    subject(:user_role) { described_class.new(user: user, role: role, facility: facility) }
    let(:user) { create(:user) }

    context "when the role is Global Billing Administrator" do
      let(:facility) { nil }
      let(:role) { described_class::GLOBAL_BILLING_ADMINISTRATOR }

      context "and the global_billing_administrator feature is enabled", feature_setting: { global_billing_administrator: true } do
        it { is_expected.to be_valid }
      end

      context "and the global_billing_administrator feature is disabled", feature_setting: { global_billing_administrator: false } do
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

  describe "soft deletion" do
    describe "facility roles" do
      let!(:user_role) { create(:user_role, :facility_staff) }
      let(:user) { user_role.user }
      let(:facility) { user_role.facility }

      it "soft deletes" do
        expect(user.operator_of?(facility)).to be_truthy
        user_role.destroy
        expect { UserRole.find(user_role.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "makes the user no longer an operator" do
        expect { user_role.destroy }.to change { user.reload.operator_of?(facility) }.to be_falsey
      end

      it "sets deleted_at" do
        expect { user_role.destroy }.to change(user_role, :deleted_at).to be_present
      end
    end
  end
end

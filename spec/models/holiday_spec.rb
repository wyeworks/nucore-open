# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples_for "allows all users" do
  context "as a global admin user" do
    let(:user) { global_admin }

    it { is_expected.to be_truthy }
  end

  context "as a facility admin user" do
    let(:user) { facility_admin }

    it { is_expected.to be_truthy }
  end

  context "as a facility admin user (different facility)" do
    let(:user) { other_facility_admin }

    it { is_expected.to be_truthy }
  end

  context "as non-admin admin user" do
    it { is_expected.to be_truthy }
  end
end

RSpec.shared_examples_for "allows global admins and facility admins" do
  context "as a global admin user" do
    let(:user) { global_admin }

    it { is_expected.to be_truthy }
  end

  context "as a facility admin user" do
    let(:user) { facility_admin }

    it { is_expected.to be_truthy }
  end

  context "as a facility admin user (different facility)" do
    let(:user) { other_facility_admin }

    it { is_expected.to be_falsey }
  end

  context "as non-admin admin user" do
    it { is_expected.to be_falsey }
  end
end

RSpec.describe Holiday do
  let(:facility) { instrument.facility }
  let(:other_facility) { create(:facility) }
  let(:instrument) { create(:setup_instrument) }
  let!(:holiday) { Holiday.create(date: 2.days.from_now) }
  let(:start_date) { holiday.date }
  let(:user) { create(:user) }
  let(:global_admin) { create(:user, :administrator) }
  let(:facility_admin) { create(:user, :facility_administrator, facility: facility) }
  let(:other_facility_admin) { create(:user, :facility_administrator, facility: other_facility) }

  describe ".allow_access?" do
    subject(:allow_access) { described_class.allow_access?(user, instrument, start_date) }

    context "when reservation start date is blank" do
      let(:start_date) { nil }

      it_behaves_like "allows all users"
    end

    context "when instrument is blank" do
      let(:facility) { create(:facility) }
      let(:instrument) { nil }

      it_behaves_like "allows all users"
    end

    context "when user is blank" do
      let(:user) { nil }

      it_behaves_like "allows all users"
    end

    context "when reservation doesnt start on a holiday" do
      let(:start_date) { holiday.date + 1.day }

      it_behaves_like "allows all users"
    end

    context "when reservation starts on a holiday" do
      context "with an instrument that doesn't restrict access" do
        it_behaves_like "allows all users"
      end

      context "with an instrument that restricts access" do
        let(:instrument) { create(:setup_instrument, restrict_holiday_access: true) }

        context "no product access groups" do
          it_behaves_like "allows global admins and facility admins"
        end

        context "with approved product access groups" do
          let!(:product_access_group) { create(:product_access_group, allow_holiday_access: true, product: instrument) }
          let!(:product_user) { create(:product_user, user: user, product_access_group: product_access_group, product: instrument) }

          it_behaves_like "allows all users"
        end

        context "with restricted product access groups" do
          let!(:product_access_group) { create(:product_access_group, allow_holiday_access: false, product: instrument) }
          let!(:product_user) { create(:product_user, user: user, product_access_group: product_access_group, product: instrument) }

          it_behaves_like "allows global admins and facility admins"
        end
      end
    end
  end

end

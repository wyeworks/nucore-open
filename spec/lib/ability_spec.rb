require "rails_helper"

RSpec.describe Ability do
  subject(:ability) { Ability.new(user, subject_resource, stub_controller) }
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:instrument_requiring_approval, facility: facility) }
  let(:stub_controller) { OpenStruct.new }
  let(:subject_resource) { facility }

  shared_examples_for "it can manage accounts" do
    it { expect(ability.can?(:manage, Account)).to be true }
  end

  shared_examples_for "it cannot manage accounts" do
    it { expect(ability.can?(:manage, Account)).to be false }
  end

  shared_examples_for "it can manage billing" do
    it { expect(ability.can?(:manage_billing, facility)).to be true }
  end

  shared_examples_for "it cannot manage billing" do
    it { expect(ability.can?(:manage_billing, facility)).to be false }
  end

  shared_examples_for "it can manage accounts for the facility" do
    it { expect(ability.can?(:manage_accounts, facility)).to be true }
  end

  shared_examples_for "it cannot manage accounts for the facility" do
    it { expect(ability.can?(:manage_accounts, facility)).to be false }
  end

  shared_examples_for "it can manage journals" do
    it { expect(ability.can?(:manage, Journal)).to be true }
  end

  shared_examples_for "it can manage order details" do
    it { expect(ability.can?(:manage, OrderDetail)).to be true }
  end

  shared_examples_for "it can manage orders" do
    it { expect(ability.can?(:manage, Order)).to be true }
  end

  shared_examples_for "it can manage price group members" do
    it { expect(ability.can?(:manage, UserPriceGroupMember)).to be true }
  end

  shared_examples_for "it cannot manage price group members" do
    it { expect(ability.can?(:manage, UserPriceGroupMember)).to be false }
  end

  shared_examples_for "it can manage reservations" do
    it { expect(ability.can?(:manage, Reservation)).to be true }
  end

  shared_examples_for "it can manage training requests" do
    it { expect(ability.can?(:manage, TrainingRequest)).to be true }
  end

  shared_examples_for "it can create but not manage training requests" do
    let(:subject_resource) { create(:training_request, product: instrument) }

    it { expect(ability.can?(:create, TrainingRequest)).to be true }

    %i(read update delete index).each do |action|
      it "cannot #{action} training requests" do
        expect(ability.can?(action, TrainingRequest)).to be false
      end
    end
  end

  shared_examples_for "it can destroy admistrative reservations" do
    let(:order) { build_stubbed(:order) }
    let(:order_detail) { build_stubbed(:order_detail, order: order) }

    it "cannot destroy a regular reservation" do
      reservation = Reservation.new(order_detail: order_detail)
      expect(ability.can?(:destroy, reservation)).to be false
    end

    it "can destroy an admin reservation" do
      reservation = Reservation.new(order_detail_id: nil)
      expect(ability.can?(:destroy, reservation)).to be true
    end
  end

  shared_examples_for "it can read notifications" do
    it { expect(ability.can?(:read, Notification)).to be true }
  end

  shared_examples_for "it cannot read notifications" do
    it { expect(ability.can?(:read, Notification)).to be false }
  end

  shared_examples_for "it can access problem reservations" do
    it { expect(ability.can?(:show_problems, Reservation)).to be true }
  end

  shared_examples_for "it cannot access problem reservations" do
    it { expect(ability.can?(:show_problems, Reservation)).to be false }
  end

  shared_examples_for "it can access disputed orders" do
    it { expect(ability.can?(:disputed, Order)).to be true }
  end

  shared_examples_for "it cannot access disputed orders" do
    it { expect(ability.can?(:disputed, Order)).to be false }
  end

  shared_examples_for "it can manage users" do
    it { expect(ability.can?(:manage, User)).to be true }
  end

  shared_examples_for "it cannot manage facility users" do
    it { expect(ability.can?(:manage_users, facility)).to be false }
  end

  describe "account manager" do
    let(:user) { create(:user, :account_manager) }

    it_behaves_like "it cannot read notifications"
    it_behaves_like "it cannot access problem reservations"
    it_behaves_like "it cannot access disputed orders"
    it_behaves_like "it cannot manage billing"
    it { expect(ability.can?(:administer, User)).to be false }

    context "in a single facility" do
      it_behaves_like "it cannot manage accounts for the facility"
      it_behaves_like "it cannot manage facility users"
    end

    context "in cross-facility" do
      let(:facility) { Facility.cross_facility }

      it_behaves_like "it can manage accounts for the facility"
      it_behaves_like "it can manage users"
    end
  end

  describe "administrator" do
    let(:user) { create(:user, :administrator) }

    context "managing price groups" do
      context "when the price group has a facility" do
        let(:subject_resource) { create(:price_group, facility: facility) }

        it_behaves_like "it can manage price group members"
      end

      context "when the price group is global" do
        let(:subject_resource) { create(:price_group, :global) }

        it_behaves_like "it cannot manage price group members"

        context "when it's the cancer center price group" do
          let(:subject_resource) { create(:price_group, :cancer_center) }

          it_behaves_like "it can manage price group members"
        end
      end
    end

    it_behaves_like "it can read notifications"

    describe StoredFile do
      describe "#download" do
        let(:subject_resource) { build_stubbed(:stored_file) }

        it { expect(ability.can?(:download, StoredFile)).to be true }
      end
    end

    it_behaves_like "it can manage training requests"
    it_behaves_like "it can access problem reservations"

    context "in a single facility" do
      it_behaves_like "it can manage accounts for the facility"
      it_behaves_like "it can manage billing"
      it_behaves_like "it can manage users"
    end

    context "in cross-facility" do
      let(:facility) { Facility.cross_facility }

      it_behaves_like "it cannot manage accounts for the facility"
      it_behaves_like "it cannot manage billing"
      it_behaves_like "it cannot manage facility users"
    end
  end

  describe "billing administrator" do
    let(:user) { create(:user, :billing_administrator) }

    it_behaves_like "it can manage accounts"
    it_behaves_like "it can manage journals"
    it_behaves_like "it can manage order details"
    it_behaves_like "it can manage orders"
    it_behaves_like "it can manage reservations"

    it "cannot administer resources" do
      expect(ability.can?(:administer, Order)).to be false
      expect(ability.can?(:administer, OrderDetail)).to be false
      expect(ability.can?(:administer, Reservation)).to be false
    end

    context "in a single facility" do
      it { expect(ability.can?(:manage_billing, facility)).to be false }
      it { expect(ability.can?(:transactions, facility)).to be false }
    end

    context "in cross-facility" do
      let(:facility) { Facility.cross_facility }

      it { expect(ability.can?(:manage_billing, facility)).to be true }
      it { expect(ability.can?(:transactions, facility)).to be true }
    end
  end

  describe "facility administrator" do
    let(:user) { create(:user, :facility_administrator, facility: facility) }

    it_behaves_like "it can manage accounts"
    it_behaves_like "it can read notifications"
    it_behaves_like "it can manage training requests"
    it_behaves_like "it can access problem reservations"
    it_behaves_like "it can access disputed orders"
    it_behaves_like "it can destroy admistrative reservations"
  end

  describe "facility director" do
    let(:user) { create(:user, :facility_director, facility: facility) }

    context "managing price groups" do
      context "when the price group has a facility" do
        let(:subject_resource) { create(:price_group, facility: facility) }

        it_behaves_like "it can manage price group members"
      end

      context "when the price group is global" do
        let(:subject_resource) { create(:price_group, :global) }

        it_behaves_like "it cannot manage price group members"

        context "when it's the cancer center price group" do
          let(:subject_resource) { create(:price_group, :cancer_center) }

          it_behaves_like "it cannot manage price group members"
        end
      end
    end

    it_behaves_like "it can manage accounts"
    it_behaves_like "it can manage training requests"
    it_behaves_like "it can read notifications"
    it_behaves_like "it can access problem reservations"
    it_behaves_like "it can access disputed orders"
    it_behaves_like "it can destroy admistrative reservations"
  end

  describe "senior staff" do
    let(:user) { create(:user, :senior_staff, facility: facility) }

    it_behaves_like "it cannot manage accounts"
    it_behaves_like "it can manage training requests"
    it_behaves_like "it can read notifications"
    it_behaves_like "it cannot access problem reservations"
    it_behaves_like "it cannot access disputed orders"
    it_behaves_like "it can destroy admistrative reservations"
  end

  describe "staff" do
    let(:user) { create(:user, :staff, facility: facility) }

    it_behaves_like "it cannot manage accounts"
    it_behaves_like "it can create but not manage training requests"
    it_behaves_like "it can read notifications"
    it_behaves_like "it cannot access problem reservations"
    it_behaves_like "it cannot access disputed orders"
    it_behaves_like "it can destroy admistrative reservations"
  end

  describe "unprivileged user" do
    let(:user) { create(:user) }

    it_behaves_like "it cannot manage accounts"
    it_behaves_like "it can create but not manage training requests"

    %i(sample_result template_result).each do |file_type|
      describe "downloading a #{file_type}" do
        let(:controller_method) { file_type.to_s.pluralize.to_sym }
        let(:subject_resource) { order_detail }

        let(:stored_file) do
          build(:stored_file,
            file_type: file_type,
            order_detail: order_detail,
            product: product,
          )
        end
        let(:order_detail) { order.order_details.first }
        let(:order) { create(:purchased_order, product: product) }
        let(:product) { create(:setup_instrument, facility: facility) }

        context "for an order belonging to the user" do
          let(:user) { order.user }

          it "is allowed to download" do
            expect(ability.can?(controller_method, order_detail)).to be true
          end
        end

        context "for an order that does not belong to the user" do
          let(:user) { create(:user) }

          it "is not allowed to download" do
            expect(ability.can?(controller_method, order_detail)).to be false
          end
        end
      end
    end

    context "when the user has notifications" do
      let(:order) { create(:purchased_order, product: product) }
      let(:product) { create(:instrument_requiring_approval) }

      before(:each) do
        merge_to_order = order.dup
        merge_to_order.save!
        order.update_attribute(:merge_with_order_id, merge_to_order.id)
        MergeNotification.create_for!(user, order.order_details.first.reload)
      end

      it_behaves_like "it can read notifications"
    end

    context "when the user has no notifications" do
      it_behaves_like "it cannot read notifications"
    end

    it_behaves_like "it cannot access problem reservations"
    it_behaves_like "it cannot access disputed orders"
  end
end

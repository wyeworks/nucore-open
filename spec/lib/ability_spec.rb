# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ability do
  subject(:ability) { Ability.new(user, subject_resource, stub_controller) }
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:instrument_requiring_approval, facility: facility) }
  let(:stub_controller) { OpenStruct.new }
  let(:subject_resource) { facility }

  shared_examples_for "it can not manage training requests" do
    let(:subject_resource) { create(:training_request, product: instrument) }

    %i(read update delete index).each do |action|
      it { is_expected.not_to be_allowed_to(action, TrainingRequest) }
    end
  end

  shared_examples_for "it can manage training requests" do
    let(:subject_resource) { create(:training_request, product: instrument) }

    it { is_expected.to be_allowed_to(:manage, TrainingRequest) }
  end

  shared_examples_for "it can destroy admistrative reservations" do
    let(:order) { build_stubbed(:order) }
    let(:order_detail) { build_stubbed(:order_detail, order: order) }

    context "with a regular reservation" do
      let(:reservation) { Reservation.new(order_detail: order_detail) }

      it { is_expected.not_to be_allowed_to(:destroy, reservation) }
    end

    context "with an admin reservation" do
      let(:reservation) { Reservation.new(order_detail_id: nil) }

      it { is_expected.to be_allowed_to(:destroy, reservation) }
    end
  end

  shared_examples_for "it allows switch_to on active, but not deactivated users" do
    let(:stub_controller) { UsersController.new }
    let(:active_user) { FactoryBot.build(:user) }
    let(:suspended_user) { FactoryBot.build(:user, :suspended) }

    it { is_expected.to be_allowed_to(:switch_to, active_user) }
    it { is_expected.not_to be_allowed_to(:switch_to, suspended_user) }
  end

  describe "account manager" do
    let(:user) { create(:user, :account_manager) }
    let(:other_user) { User.new }

    it { is_expected.to be_allowed_to(:manage_users, Facility.cross_facility) }
    it { is_expected.not_to be_allowed_to(:read, Notification) }
    it { is_expected.not_to be_allowed_to(:show_problems, Reservation) }
    it { is_expected.not_to be_allowed_to(:manage_billing, facility) }
    it { is_expected.not_to be_allowed_to(:administer, User) }
    it { is_expected.not_to be_allowed_to(:batch_update, Order) }
    it_is_not_allowed_to([:batch_update, :cancel, :index], Reservation)
    it_is_not_allowed_to([:edit, :update]) { FactoryBot.create(:user) }

    context "in a single facility" do
      it { is_expected.not_to be_allowed_to(:manage_accounts, facility) }
      it { is_expected.not_to be_allowed_to(:manage, Account) }
      it { is_expected.not_to be_allowed_to(:manage, AccountUser) }
      it { is_expected.not_to be_allowed_to(:manage, User) }
      it { is_expected.not_to be_allowed_to(:switch_to, other_user) }
    end

    shared_examples_for "correct User permissions" do
      context "when create_users feature is on", feature_setting: { create_users: true } do
        it_is_allowed_to([:new, :create, :read, :index, :accounts, :search], User)
        it_is_not_allowed_to([:switch_to, :edit, :update, :suspend, :unsuspend, :orders], User)
      end

      context "when create_users feature is off", feature_setting: { create_users: false } do
        it_is_allowed_to([:read, :index, :accounts, :search], User)
        it_is_not_allowed_to([:new, :create, :edit, :update, :switch_to, :suspend, :unsuspend, :orders], User)
      end
    end

    context "in cross-facility" do
      let(:facility) { Facility.cross_facility }

      it { is_expected.to be_allowed_to(:manage_accounts, facility) }
      it_is_allowed_to([:new, :create, :read, :edit, :update, :suspend, :unsuspend], Account)
      it { is_expected.to be_allowed_to(:manage, AccountUser) }

      it_behaves_like "correct User permissions"
    end

    context "in no facility" do
      let(:facility) { nil }

      it { is_expected.to be_allowed_to(:manage, AccountUser) }

      it_behaves_like "correct User permissions"
    end
  end

  describe "administrator" do
    let(:user) { create(:user, :administrator) }

    it_behaves_like "it allows switch_to on active, but not deactivated users"

    context "managing price groups" do
      context "when the price group has a facility" do
        let(:subject_resource) { create(:price_group, facility: facility) }

        it { is_expected.to be_allowed_to(:manage, UserPriceGroupMember) }
      end

      context "when the price group is global" do
        let(:subject_resource) { create(:price_group, :global) }

        it { is_expected.not_to be_allowed_to(:manage, UserPriceGroupMember) }

        context "when it's the cancer center price group" do
          let(:subject_resource) { create(:price_group, :cancer_center) }

          it { is_expected.to be_allowed_to(:manage, UserPriceGroupMember) }
        end
      end
    end

    it { is_expected.to be_allowed_to(:read, Notification) }
    it { is_expected.to be_allowed_to(:manage, Schedule) }

    describe StoredFile do
      describe "#download" do
        let(:subject_resource) { build_stubbed(:stored_file) }

        it { is_expected.to be_allowed_to(:download, StoredFile) }
      end
    end

    it { is_expected.to be_allowed_to(:manage, TrainingRequest) }
    it { is_expected.to be_allowed_to(:show_problems, Reservation) }
    it { is_expected.to be_allowed_to(:manage_users, Facility.cross_facility) }

    context "in a single facility" do
      let(:internal_user) { FactoryBot.create(:user) }
      let(:external_user) { FactoryBot.create(:user, :external) }
      it_is_allowed_to([:bring_online, :create, :edit, :new, :update], OfflineReservation)
      it { is_expected.to be_allowed_to(:manage, User) }
      it { is_expected.to be_allowed_to(:manage_accounts, facility) }
      it { is_expected.to be_allowed_to(:manage_billing, facility) }
      it { is_expected.to be_allowed_to(:batch_update, Order) }
      it { is_expected.to be_allowed_to(:batch_update, Reservation) }

      context "when create_users feature is on", feature_setting: { create_users: true } do
        context "when user is external" do
          it { is_expected.to be_allowed_to(:edit, external_user) }
          it { is_expected.to be_allowed_to(:update, external_user) }
        end

        context "when user is internal" do
          it { is_expected.to be_allowed_to(:edit, internal_user) }
          it { is_expected.to be_allowed_to(:update, internal_user) }
        end
      end

      context "when create_users feature is off", feature_setting: { create_users: false } do
        context "when user is external" do
          it { is_expected.not_to be_allowed_to(:edit, external_user) }
          it { is_expected.not_to be_allowed_to(:update, external_user) }
        end

        context "when user is internal" do
          it { is_expected.not_to be_allowed_to(:edit, internal_user) }
          it { is_expected.not_to be_allowed_to(:update, internal_user) }
        end
      end
    end

    context "in cross-facility" do
      let(:facility) { Facility.cross_facility }

      it { is_expected.to be_allowed_to(:manage, User) }
      it { is_expected.not_to be_allowed_to(:manage_accounts, facility) }
      it { is_expected.not_to be_allowed_to(:manage_billing, facility) }
    end

    context "in no facility" do
      let(:facility) { nil }

      it { is_expected.not_to be_allowed_to(:manage, User) }
    end
  end

  describe "global billing administrator", feature_setting: { global_billing_administrator: true } do
    let(:user) { create(:user, :global_billing_administrator) }

    it { is_expected.to be_allowed_to(:manage, Account) }
    it { is_expected.to be_allowed_to(:manage, Journal) }
    it { is_expected.to be_allowed_to(:manage, OrderDetail) }
    it_is_not_allowed_to([:edit, :update]) { FactoryBot.create(:user) }

    context "in a single facility" do
      it { is_expected.not_to be_allowed_to(:manage_users, facility) }
      it_is_allowed_to([:send_receipt, :show], Order)
      it { is_expected.not_to be_allowed_to(:manage_billing, facility) }
      it { is_expected.not_to be_allowed_to(:transactions, facility) }
      it { is_expected.not_to be_allowed_to(:manage, Reservation) }
    end

    context "in cross-facility" do
      let(:facility) { Facility.cross_facility }

      context "with the users tab active", feature_setting: { global_billing_administrator_users_tab: true } do
        it { is_expected.to be_allowed_to(:manage_users, facility) }
      end

      context "with the users tab inactive", feature_setting: { global_billing_administrator_users_tab: false } do
        it { is_expected.not_to be_allowed_to(:manage_users, facility) }
      end

      %i(disputed_orders manage_billing movable_transactions transactions reassign_chart_strings confirm_transactions move_transactions).each do |action|
        it { is_expected.to be_allowed_to(action, facility) }
      end
      it_is_allowed_to([:accounts, :index, :orders, :show], User)
      it_is_not_allowed_to([:create, :switch_to], User)
      it { is_expected.to be_allowed_to(:show, Order) }
      it_is_not_allowed_to([:edit, :update], Reservation)
      it { is_expected.not_to be_allowed_to(:administer, Product) }
      it_is_allowed_to(:manage, Statement)
    end

    context "in no facility" do
      let(:facility) { nil }

      context "with the users tab active", feature_setting: { global_billing_administrator_users_tab: true } do
        it { is_expected.to be_allowed_to(:manage_users, Facility.cross_facility) }
      end

      context "with the users tab inactive", feature_setting: { global_billing_administrator_users_tab: false } do
        it { is_expected.not_to be_allowed_to(:manage_users, Facility.cross_facility) }
      end

      it { is_expected.to be_allowed_to(:manage_billing, Facility.cross_facility) }
      it_is_not_allowed_to([:create, :switch_to], User)
      it_is_not_allowed_to(:manage, Statement)
    end
  end

  describe "facility administrator" do
    let(:user) { create(:user, :facility_administrator, facility: facility) }

    it_is_allowed_to([:bring_online, :create, :edit, :new, :update], OfflineReservation)
    it { is_expected.to be_allowed_to(:manage, Account) }
    it { is_expected.to be_allowed_to(:read, Notification) }
    it { is_expected.to be_allowed_to(:manage, Schedule) }
    it { is_expected.to be_allowed_to(:manage, TrainingRequest) }
    it { is_expected.to be_allowed_to(:show_problems, Reservation) }
    it { is_expected.to be_allowed_to(:batch_update, Order) }
    it_is_allowed_to([:batch_update, :cancel, :index], Reservation)
    it { is_expected.to be_allowed_to(:administer, User) }
    it { is_expected.to be_allowed_to(:manage, PriceGroup) }
    it { is_expected.to be_allowed_to(:manage, ScheduleRule) }
    it { is_expected.to be_allowed_to(:manage, ProductAccessGroup) }
    it_is_not_allowed_to([:edit, :update]) { FactoryBot.create(:user) }

    it_behaves_like "it can destroy admistrative reservations"
    it_behaves_like "it allows switch_to on active, but not deactivated users"
  end

  describe "facility director" do
    let(:user) { create(:user, :facility_director, facility: facility) }

    context "managing price groups" do
      context "when the price group has a facility" do
        let(:subject_resource) { create(:price_group, facility: facility) }

        it { is_expected.to be_allowed_to(:manage, UserPriceGroupMember) }
      end

      context "when the price group is global" do
        let(:subject_resource) { create(:price_group, :global) }

        it { is_expected.not_to be_allowed_to(:manage, UserPriceGroupMember) }

        context "when it's the cancer center price group" do
          let(:subject_resource) { create(:price_group, :cancer_center) }

          it { is_expected.not_to be_allowed_to(:manage, UserPriceGroupMember) }
        end
      end
    end

    it_is_allowed_to([:bring_online, :create, :edit, :new, :update], OfflineReservation)
    it { is_expected.to be_allowed_to(:manage, Account) }
    it { is_expected.to be_allowed_to(:manage, TrainingRequest) }
    it { is_expected.to be_allowed_to(:read, Notification) }
    it { is_expected.to be_allowed_to(:manage, Schedule) }
    it { is_expected.to be_allowed_to(:show_problems, Reservation) }
    it { is_expected.to be_allowed_to(:batch_update, Order) }
    it_is_allowed_to([:batch_update, :cancel, :index], Reservation)
    it { is_expected.to be_allowed_to(:manage, ScheduleRule) }
    it { is_expected.to be_allowed_to(:manage, ProductAccessGroup) }
    it { is_expected.to be_allowed_to(:administer, User) }
    it { is_expected.not_to be_allowed_to(:manage_accounts, Facility.cross_facility) }
    it { is_expected.not_to be_allowed_to(:manage_billing, Facility.cross_facility) }
    it { is_expected.not_to be_allowed_to(:manage_users, Facility.cross_facility) }
    it_behaves_like "it can destroy admistrative reservations"
    it_behaves_like "it allows switch_to on active, but not deactivated users"
    it_behaves_like "it can manage training requests"

    context "when facility_directors_can_manage_price_groups enabled", feature_setting: { facility_directors_can_manage_price_groups: true } do
      it_is_allowed_to(:manage, PriceGroup)
      it_is_allowed_to(:manage, PricePolicy)
      it_is_allowed_to(:manage, InstrumentPricePolicy)
      it_is_allowed_to(:manage, ItemPricePolicy)
      it_is_allowed_to(:manage, ServicePricePolicy)
    end

    context "when facility_directors_can_manage_price_groups disabled", feature_setting: { facility_directors_can_manage_price_groups: false } do
      it_is_allowed_to([:show, :index], PriceGroup)
      it_is_not_allowed_to([:create, :edit, :update, :destroy], PriceGroup)
      it_is_allowed_to([:show, :index], PricePolicy)
      it_is_not_allowed_to([:create, :edit, :update, :destroy], PricePolicy)
      it_is_allowed_to([:show, :index], InstrumentPricePolicy)
      it_is_not_allowed_to([:create, :edit, :update, :destroy], InstrumentPricePolicy)
      it_is_allowed_to([:show, :index], ItemPricePolicy)
      it_is_not_allowed_to([:create, :edit, :update, :destroy], ItemPricePolicy)
      it_is_allowed_to([:show, :index], ServicePricePolicy)
      it_is_not_allowed_to([:create, :edit, :update, :destroy], ServicePricePolicy)
    end
  end

  describe "facility billing administrator" do
    let(:user) { create(:user, :facility_billing_administrator, facility: facility) }

    it_is_allowed_to(:manage, Journal)
    it_is_allowed_to(:manage, Statement)
    it_is_allowed_to(:manage, OrderDetail)
    it_is_allowed_to(:manage, Account)
    it_is_not_allowed_to([:create, :edit, :update, :suspend, :switch_to], User)
    it_is_allowed_to([:accounts, :index, :orders, :show, :administer], User)

    context "in a single facility" do
      let(:subject_resource) { facility }

      it_is_allowed_to([:list, :dashboard, :show], Facility)
      it_is_allowed_to([:index, :show, :timeline], Reservation)
      it_is_not_allowed_to([:edit, :update, :destroy], Reservation)
      it_is_allowed_to([:administer, :index, :view_details, :schedule, :show], Product)
      it_is_not_allowed_to([:edit, :update, :destroy], Product)
      it_is_allowed_to([:show, :index], PriceGroup)
      it_is_not_allowed_to([:create, :edit, :update, :destroy], PriceGroup)
      it_is_allowed_to([:show, :index], PricePolicy)
      it_is_not_allowed_to([:create, :edit, :update, :destroy], PricePolicy)

      it { is_expected.to be_allowed_to(:index, BundleProduct) }
      it { is_expected.to be_allowed_to(:index, ScheduleRule) }
      it { is_expected.to be_allowed_to(:index, ServicePricePolicy) }
      it { is_expected.to be_allowed_to(:index, ProductAccessory) }
      it { is_expected.to be_allowed_to(:index, ProductAccessGroup) }
      it { is_expected.to be_allowed_to(:edit, PriceGroupProduct) }
      it { is_expected.to be_allowed_to(:index, StoredFile) }

      it { is_expected.to be_allowed_to(:manage, AccountUser) }

      it { is_expected.to be_allowed_to(:manage_users, subject_resource) }
      it { is_expected.to be_allowed_to(:manage_billing, subject_resource) }
      it_is_allowed_to([:accounts, :index, :orders, :show, :administer], User)
      it_is_not_allowed_to([:create, :edit, :update, :switch_to], User)
      it_is_allowed_to([:send_receipt, :show], Order)
      it_is_not_allowed_to([:update, :edit, :new, :destroy], Order)

      %i(disputed_orders movable_transactions transactions reassign_chart_strings confirm_transactions move_transactions).each do |action|
        it { is_expected.to be_allowed_to(action, subject_resource) }
      end
    end

    context "in cross-facility" do
      let(:subject_resource) { Facility.cross_facility }

      it_is_not_allowed_to(:show, Reservation)
      it_is_not_allowed_to([:administer, :index, :show], Product)
      it_is_not_allowed_to([:show, :index], PriceGroup)

      it { is_expected.not_to be_allowed_to(:manage_users, subject_resource) }
      it { is_expected.not_to be_allowed_to(:manage_billing, subject_resource) }
      it_is_not_allowed_to([:accounts, :index, :orders, :show, :create, :switch_to], User)
      it_is_not_allowed_to([:send_receipt, :show], Order)

      %i(disputed_orders manage_billing movable_transactions transactions reassign_chart_strings confirm_transactions move_transactions).each do |action|
        it { is_expected.not_to be_allowed_to(action, facility) }
      end
    end
  end

  shared_examples_for "it has common staff abilities" do
    it { is_expected.not_to be_allowed_to(:disputed, Order) }
    it { is_expected.not_to be_allowed_to(:manage, Account) }
    it { is_expected.to be_allowed_to(:batch_update, Order) }
    it_is_allowed_to([:batch_update, :cancel, :index], Reservation)
    it { is_expected.to be_allowed_to(:read, Notification) }
    it { is_expected.to be_allowed_to(:read, Schedule) }
    it { is_expected.to be_allowed_to(:administer, User) }
    it { is_expected.to be_allowed_to(:read, UserPriceGroupMember) }
    it { is_expected.not_to be_allowed_to(:manage, PriceGroup) }
    it { is_expected.to be_allowed_to(:index, ScheduleRule) }
    it { is_expected.to be_allowed_to(:index, ProductAccessGroup) }

    it_behaves_like "it can destroy admistrative reservations"
    it_behaves_like "it allows switch_to on active, but not deactivated users"

    it { is_expected.not_to be_allowed_to(:manage, Reservation) }
    context "when managing reservations" do
      let(:instrument) { create(:instrument, facility: facility) }
      let(:subject_resource) { create(:reservation, product: instrument) }

      it { is_expected.to be_allowed_to(:read, ProductAccessory) }
      it { is_expected.to be_allowed_to(:manage, Reservation) }
    end

    context "when managing order details" do
      let(:order) { build_stubbed(:order, facility: facility) }
      let(:subject_resource) { build_stubbed(:order_detail, order: order) }

      it { is_expected.to be_allowed_to(:manage, OrderDetail) }
    end
  end

  describe "senior staff" do
    let(:user) { create(:user, :senior_staff, facility: facility) }

    it_behaves_like "it has common staff abilities"
    it { is_expected.to be_allowed_to(:show_problems, Reservation) }
    it { is_expected.to be_allowed_to(:show_problems, Order) }
    it_is_allowed_to([:bring_online, :create, :edit, :new, :update], OfflineReservation)
    it { is_expected.to be_allowed_to(:manage, TrainingRequest) }
    it { is_expected.to be_allowed_to(:manage, ScheduleRule) }
    it { is_expected.to be_allowed_to(:manage, ProductAccessGroup) }
    it_behaves_like "it can manage training requests"
  end

  describe "staff" do
    let(:user) { create(:user, :staff, facility: facility) }

    it_behaves_like "it has common staff abilities"
    it { is_expected.not_to be_allowed_to(:show_problems, Reservation) }
    it_is_not_allowed_to([:bring_online, :create, :edit, :new, :update], OfflineReservation)
    it { is_expected.to be_allowed_to(:create, TrainingRequest) }
    it_behaves_like "it can not manage training requests"
    it_is_not_allowed_to([:create, :update, :destroy], ScheduleRule)
    it_is_not_allowed_to([:create, :update, :destroy], ProductAccessGroup)
  end

  describe "unprivileged user" do
    let(:user) { create(:user) }

    it { is_expected.not_to be_allowed_to(:manage, Account) }
    it { is_expected.to be_allowed_to(:create, TrainingRequest) }
    it_behaves_like "it can not manage training requests"
    it { is_expected.not_to be_allowed_to(:switch_to, user) }
    it_is_not_allowed_to([:cancel, :index], Reservation)

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
            is_expected.to be_allowed_to(controller_method, order_detail)
          end
        end

        context "for an order that does not belong to the user" do
          let(:user) { create(:user) }

          it "is not allowed to download" do
            is_expected.not_to be_allowed_to(controller_method, order_detail)
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

      it { is_expected.to be_allowed_to(:read, Notification) }
    end

    context "when the user has no notifications" do
      it { is_expected.not_to be_allowed_to(:read, Notification) }
    end

    it { is_expected.not_to be_allowed_to(:manage, Reservation) }
    it { is_expected.not_to be_allowed_to(:show_problems, Reservation) }
    it { is_expected.not_to be_allowed_to(:disputed, Order) }
    it { is_expected.not_to be_allowed_to(:manage, User) }
  end

  describe "account administrator" do
    let(:user) { create(:user) }
    let(:account) { create(:setup_account, owner: user) }

    context "managing accounts" do
      let(:subject_resource) { account }

      it_is_allowed_to([:manage], Account)
      it_is_allowed_to([:manage], AccountUser)
      it_is_allowed_to [:show, :suspend, :unsuspend, :user_search, :user_accounts, :statements, :show_statement, :index], Statement
    end

    context "when managing order details of own account" do
      let(:order) { build_stubbed(:order, facility: facility) }
      let(:subject_resource) { build_stubbed(:order_detail, order: order, account: account) }

      it_is_allowed_to([:show, :update, :dispute], OrderDetail)
    end
  end
end

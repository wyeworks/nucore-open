# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Move Transactions", :js, feature_setting: { move_transactions_account_roles: true } do
  let(:facility) { create(:setup_facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:account_owner) { create(:user) }
  let(:business_admin) { create(:user) }
  let(:regular_user) { create(:user) }
  let(:another_user) { create(:user) }

  let!(:source_account) { create(:setup_account, :with_account_owner, owner: account_owner) }
  let!(:target_account) { create(:setup_account, :with_account_owner, owner: account_owner) }
  let!(:other_account) { create(:setup_account, :with_account_owner, owner: another_user) }

  let!(:order_details) do
    [
      create(:complete_order, product: item, account: source_account).order_details.first,
      create(:complete_order, product: item, account: source_account).order_details.first,
      create(:complete_order, product: item, account: source_account).order_details.first
    ]
  end

  let(:chart_strings_name_upcase) { I18n.t("Chart_strings") }
  let(:chart_strings_name_downcase) { I18n.t("chart_strings_downcase") }
  let(:chart_string_name_upcase) { I18n.t("Chart_string") }

  before do
    create(:account_user, :business_administrator, user: business_admin, account: source_account, created_by: account_owner.id)
    create(:account_user, :business_administrator, user: business_admin, account: target_account, created_by: account_owner.id)

    create(:account_user, :purchaser, user: regular_user, account: source_account, created_by: account_owner.id)

    [source_account, target_account].each do |account|
      create(:account_price_group_member, account: account, price_group: PriceGroup.base)
    end
  end

  context "with feature flag ON", feature_setting: { move_transactions_account_roles: true } do
    RSpec.shared_examples "can reassign chart strings" do
      it "can reassign chart strings" do
        visit movable_transactions_transactions_path

        click_link "Select All"

        click_button "Reassign #{chart_strings_name_upcase}"

        expect(page).to have_content("All #{chart_strings_name_downcase} listed above are available")

        select_from_chosen target_account.account_list_item, from: "Payment Source"

        click_button "Reassign #{chart_string_name_upcase}"

        expect(page).to have_content("Confirm Transaction Moves")

        click_button "Reassign #{chart_string_name_upcase}"

        expect(page).to have_content("3 transactions were reassigned")

        order_details.each do |order_detail|
          expect(order_detail.reload.account).to eq(target_account)
        end
      end
    end

    context "as an account owner" do
      before { login_as account_owner }

      it_behaves_like "can reassign chart strings"
    end

    context "as business administrator" do
      before { login_as business_admin }

      it_behaves_like "can reassign chart strings"
    end

    context "when user has no administered order details" do
      let(:user_without_orders) { create(:user) }
      let!(:empty_account) { create(:setup_account, :with_account_owner, owner: user_without_orders) }

      before { login_as user_without_orders }

      it "shows a message saying there are no movable transactions" do
        visit movable_transactions_transactions_path
        expect(page).to have_content("You have no movable transactions.")
      end
    end
  end
end

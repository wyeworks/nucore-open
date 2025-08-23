# frozen_string_literal: true

require "rails_helper"

RSpec.describe "All Transactions Search", :js do
  # Defined in spec/support/contexts/cross_core_context.rb
  include_context "cross core orders"

  let(:director) { create(:user, :facility_director, facility: facility) }
  let!(:orders) do
    accounts.map { |account| create(:complete_order, product: item, account: account) }
  end

  let(:order_detail) { orders.first.order_details.first }

  before do
    all_cross_core_orders.each do |order|
      order.order_details.each(&:complete!)
    end
  end

  describe "sorting by columns" do
    let(:some_account) { facility.order_details.complete.last.account }

    before { login_as director }

    it "can sort by order number while filtering by account owner and type" do
      # use custom string to ease matching
      allow_any_instance_of(Order).to receive(:id).and_wrap_original do |method|
        "test_prefix_#{method.call}"
      end

      visit facility_transactions_path(facility)

      select_from_chosen(some_account.model_name.human, from: "Payment Source Type")
      select_from_chosen(some_account.owner_user.full_name, from: "Owners")

      click_button "Filter"

      expect(page).to have_content("Transaction History")

      within("#table_billing") do
        first("a", text: "Order").click
      end

      order_ids =
        facility
        .order_details
        .complete
        .for_accounts(some_account)
        .pluck(:order_id)

      expect(order_ids.map { |odid| "test_prefix_#{odid}" }).to appear_in_order
    end
  end

  describe "date field order" do
    let(:order_detail_ids) do
      page.all("a.manage-order-detail").map(&:text)
    end
    let(:order_details) do
      OrderDetail.where(id: order_detail_ids)
    end

    before do
      login_as director

      OrderDetail.all.each_with_index do |order_detail, index|
        order_detail.update_column(:fulfilled_at, index.days.from_now)
        order_detail.update_column(:ordered_at, (20 - index).days.from_now)
      end
    end

    context "when filter by fulfiled status" do
      let(:sorted_order_details) do
        order_details.order(fulfilled_at: :desc)
      end

      it "can order by fulfilled_at" do
        visit facility_transactions_path(facility)

        expect(
          sorted_order_details.map do |od|
            I18n.l(od.fulfilled_at.to_date, format: :usa)
          end
        ).to appear_in_order
      end
    end

    context "when filter by ordered_at" do
      let(:sorted_order_details) do
        order_details.order(ordered_at: :desc)
      end

      it "can order by ordered_at" do
        visit facility_transactions_path(facility)

        select("Ordered", from: "search[date_range_field]")

        click_button("Filter")

        expect(
          sorted_order_details.map do |od|
            I18n.l(od.ordered_at.to_date, format: :usa)
          end
        ).to appear_in_order
      end
    end

    context "when statemented/journaled" do
      include TextHelpers::Translation

      def translation_scope
        ""
      end

      let(:account) { create(:account, :with_account_owner) }
      let(:sorted_order_details) do
        order_details
      end
      let(:statemented_order_detail) { facility.order_details.complete.last }

      before do
        statement = Statement.create!(facility:, account:, created_by: director.id)
        StatementRow.create!(
          statement:,
          order_detail: statemented_order_detail,
        )
        statemented_order_detail.update_columns(statement_id: statement.id)

      end

      it "can filter orders" do
        visit facility_transactions_path(facility)

        select(
          text("admin.transaction_search.date_range_fields.journal_or_statement_date"),
          from: "search[date_range_field]",
        )

        click_button("Filter")

        expect(
          sorted_order_details.map do |od|
            I18n.l(od.journal_or_statement_date.to_date, format: :usa)
          end
        ).to appear_in_order
      end
    end
  end

  it "can do a basic search" do
    login_as director
    visit facility_transactions_path(facility)
    expected_default_date = 1.month.ago.beginning_of_month
    expect(page).to have_field("Start Date", with: I18n.l(expected_default_date.to_date, format: :usa))

    select_from_chosen accounts.second.account_list_item, from: "Payment Sources"
    click_button "Filter"

    expect(page).to have_content("Total")
    expect(page).not_to have_link(order_detail.id.to_s, href: manage_facility_order_order_detail_path(order_detail.facility, order_detail.order, order_detail))
    expect(page).to have_link(orders.second.order_details.first.id.to_s, href: manage_facility_order_order_detail_path(orders.second.facility, orders.second, orders.second.order_details.first))

    # Cross Core orders
    expect(page).not_to have_link(originating_order_facility1.id.to_s, href: facility_order_path(originating_order_facility1.facility, originating_order_facility1))
    expect(page).to have_link(cross_core_orders[2].id.to_s, href: facility_order_path(cross_core_orders[2].facility, cross_core_orders[2]))
    expect(page).to have_css(".fa-users", count: 1) # cross_core_orders[2] is a cross-core order that didn't originate in the current facility
  end

  it "is accessible", :js do
    skip "Accessibility tests temporarily disabled during Bootstrap 2->3 migration"
    login_as director
    visit facility_transactions_path(facility)

    # Skip these two violations because the chosen JS library is hard to make accessible
    expect(page).to be_axe_clean.skipping("label", "select-name")
  end

  it "does not show the Participating Facilities filter" do
    login_as director
    visit transactions_path

    expect(page).to have_content("Transaction History")
    expect(page).not_to have_content("Participating Facilities")
  end

  describe "price group column and filtering", feature_setting: { billing_table_price_groups: true } do
    let(:price_group1) { create(:price_group, facility: facility, name: "Research Group") }
    let(:price_group2) { create(:price_group, facility: facility, name: "External Group") }

    before do
      AccountPriceGroupMember.create!(account: accounts.first, price_group: price_group1)
      AccountPriceGroupMember.create!(account: accounts.second, price_group: price_group2)
      login_as director
    end

    it "shows Pricing Group column with correct values" do
      visit facility_transactions_path(facility)

      within("#table_billing") do
        expect(page).to have_content("Pricing Group")
      end

      expect(page).to have_content("Research Group")
      expect(page).to have_content("External Group")
    end

    it "can sort by pricing group" do
      visit facility_transactions_path(facility)

      within("#table_billing") do
        click_link "Pricing Group"
      end

      expect(page).to have_current_path(/sort=pricing_group/)
    end

    it "can filter by price groups" do
      visit facility_transactions_path(facility)

      select_from_chosen price_group1.name, from: "Price Group"
      click_button "Filter"

      expect(page).to have_content(accounts.first.description)
      expect(page).not_to have_content(accounts.second.description)
    end
  end

  context "when price groups feature is disabled", feature_setting: { billing_table_price_groups: false } do
    before { login_as director }

    it "does not show Pricing Group column" do
      visit facility_transactions_path(facility)

      within("#table_billing") do
        expect(page).not_to have_content("Pricing Group")
      end
    end

    it "does not show Price Group filter" do
      visit facility_transactions_path(facility)

      expect(page).not_to have_select("Price Group")
    end
  end
end

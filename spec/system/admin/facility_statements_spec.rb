# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Facility Statement Admin" do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }
  let(:item) { create(:setup_item, facility:) }
  let(:accounts) { create_list(:account, 3, :with_account_owner, type: Account.config.statement_account_types.first) }
  let(:orders) do
    accounts.map { |account| create(:complete_order, product: item, account:) }
  end

  let(:order_details) { orders.map(&:order_details).flatten }

  before do
    order_details.each do |detail|
      detail.update(reviewed_at: 1.day.ago)
    end
  end

  describe "filtering on Create Statement" do
    it "can do a basic filter" do
      login_as director
      visit new_facility_statement_path(facility)
      select accounts.first.account_list_item, from: "Payment Sources"
      click_button "Filter"

      expect(page).to have_link(order_details.first.id.to_s, href: manage_facility_order_order_detail_path(facility, orders.first, order_details.first))
      expect(page).not_to have_link(order_details.second.id.to_s, href: manage_facility_order_order_detail_path(facility, orders.second, order_details.second))
    end
  end

  describe "parent statement functionality", :js do
    let(:account) { accounts.first }
    let(:order_detail) { order_details.first }
    let!(:parent_statement) do
      create(:statement, account: account, facility: facility, created_by: director.id)
    end

    before do
      login_as director
    end

    context "when reference_statement_invoice_number feature is on", feature_setting: { reference_statement_invoice_number: true } do
      it "creates child statement with parent reference" do
        visit new_facility_statement_path(facility)

        click_link "Select All"

        click_button "Create"

        expect(page).to have_content("Create New #{I18n.t('Statement')}")

        fill_in "parent_invoice_number", with: parent_statement.invoice_number

        click_button "Save"

        expect(page).to have_current_path(new_facility_statement_path(facility))
        expect(page).to have_content("Notifications sent successfully")

        child_statement = Statement.find_by(invoice_number: "#{parent_statement.invoice_number}-2")
        expect(child_statement).to be_present
        expect(child_statement.parent_statement_id).to eq(parent_statement.id)
      end

      it "shows error for invalid parent invoice number format" do
        visit new_facility_statement_path(facility)

        click_link "Select All"

        click_button "Create"

        fill_in "parent_invoice_number", with: "invalid-format"
        click_button "Save"

        expect(page).to have_content("Invalid invoice number format")
      end

      it "creates standard statement when parent invoice number is left blank" do
        visit new_facility_statement_path(facility)

        click_link "Select All"

        click_button "Create"

        click_button "Save"

        expect(page).to have_current_path(new_facility_statement_path(facility))
        expect(page).to have_content("Notifications sent successfully")

        standard_statement = Statement.order(invoice_number: :asc).last
        expect(standard_statement.parent_statement_id).to be_nil
        expect(standard_statement.invoice_number).to eq(standard_statement.build_invoice_number)
      end
    end

    context "when reference_statement_invoice_number feature is off", feature_setting: { reference_statement_invoice_number: false } do
      it "does not show parent statement modal" do
        visit new_facility_statement_path(facility)

        click_link "Select All"

        click_button "Create"

        expect(page).to have_current_path(new_facility_statement_path(facility))
        expect(page).to have_content("Notifications sent successfully")

        standard_statement = Statement.order(invoice_number: :asc).last
        expect(standard_statement.parent_statement_id).to be_nil
        expect(standard_statement.invoice_number).to eq(standard_statement.build_invoice_number)
      end
    end
  end

  describe "searching statements" do
    let!(:statement1) { create(:statement, created_at: 9.days.ago, order_details: [order_details.first], account: order_details.first.account, facility:) }
    let!(:statement2) { create(:statement, created_at: 6.days.ago, order_details: [order_details.second], account: order_details.second.account, facility:) }
    let!(:statement3) { create(:statement, created_at: 3.days.ago, order_details: [order_details.last], account: order_details.last.account, facility:) }

    before do
      order_details.last.change_status!(OrderStatus.unrecoverable)
      login_as director
      visit facility_statements_path(facility)
    end

    it "can filter by the account" do
      expect(page).to have_content(statement1.invoice_number)
      expect(page).to have_content(statement2.invoice_number)

      select statement1.account.account_list_item, from: "Payment Sources"
      click_button "Filter"

      expect(page).to have_content(statement1.invoice_number)
      expect(page).not_to have_content(statement2.invoice_number)

      unselect statement1.account.account_list_item, from: "Payment Sources"
      select statement2.account.account_list_item, from: "Payment Sources"
      click_button "Filter"

      expect(page).not_to have_content(statement1.invoice_number)
      expect(page).to have_content(statement2.invoice_number)
    end

    it "can filter by the status" do
      expect(page).to have_content(statement1.invoice_number)
      expect(page).to have_content(statement2.invoice_number)
      expect(page).to have_content(statement3.invoice_number)

      select "Unrecoverable", from: "Status"
      click_button "Filter"

      expect(page).not_to have_content(statement1.invoice_number)
      expect(page).not_to have_content(statement2.invoice_number)
      expect(page).to have_content(statement3.invoice_number)
    end

    it "can filter by the owner/business admin" do
      expect(page).to have_content(statement1.invoice_number)
      expect(page).to have_content(statement2.invoice_number)

      select statement1.account.owner_user.full_name, from: "Account Admins"
      click_button "Filter"

      expect(page).to have_content(statement1.invoice_number)
      expect(page).not_to have_content(statement2.invoice_number)

      unselect statement1.account.owner_user.full_name, from: "Account Admins"
      select statement2.account.owner_user.full_name, from: "Account Admins"
      click_button "Filter"

      expect(page).not_to have_content(statement1.invoice_number)
      expect(page).to have_content(statement2.invoice_number)
    end

    it "can filter by dates" do
      fill_in "Start Date", with: I18n.l(4.days.ago.to_date, format: :usa)
      click_button "Filter"

      expect(page).not_to have_content(statement1.invoice_number)
      expect(page).not_to have_content(statement2.invoice_number)
      expect(page).to have_content(statement3.invoice_number)

      fill_in "Start Date", with: ""
      fill_in "End Date", with: I18n.l(4.days.ago.to_date, format: :usa)

      click_button "Filter"
      expect(page).to have_content(statement1.invoice_number)
      expect(page).to have_content(statement2.invoice_number)
      expect(page).not_to have_content(statement3.invoice_number)
    end

    it "sends a csv in an email" do
      expect { click_link "Export as CSV" }.to(
        enqueue_job(CsvReportEmailJob).with(
          Reports::StatementSearchReport.to_s, director.email, Hash,
        )
      )

      perform_enqueued_jobs
      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to eq("#{I18n.t('Statement')} Export")
    end
  end

  describe "statements table order notes" do
    let(:account) { order_details.first.account }
    let!(:statement) do
      create(
        :statement,
        created_at: 9.days.ago,
        order_details: order_details.slice(..3),
        account:,
        facility:
      )
    end

    before do
      login_as director

      order_details.first.update(reconciled_note: "Some note #123")
      order_details.map do |od|
        od.update(state: :reconciled)
      end
    end

    it "show order details notes if ff is on" do
      visit facility_statements_path(facility)

      within("table.table") do
        expect(page).to have_content(account.description)
        expect(page).to have_content("Some note #123")
        expect(page).to_not have_element("a", text: "Expand")
      end
    end

    it "shows expand button when more than one note", :js do
      order_details.second.update(reconciled_note: "Other note #456")

      visit facility_statements_path(facility)

      within("table.table") do
        expect(page).to have_content(account.description)
        expect(page).to have_content("Some note #123")
        expect(page).to_not have_content("Other note #456")
        expect(page).to have_element("a", text: "Expand")
        click_link("Expand")

        expect(page).to have_content("Other note #456")
      end
    end
  end

  describe "resending statement emails", :js, feature_setting: { send_statement_emails: true } do
    let!(:statement) { create(:statement, created_at: 3.days.ago, order_details: [order_details.first], account: order_details.first.account, facility:) }

    before do
      login_as director
      visit facility_statements_path(facility)
    end

    it "resends the statement email", :perform_enqueued_jobs do
      accept_confirm { click_link "Resend" }

      # sometimes takes longer to load and causes failures in CI
      expect(page).to have_content("Notifications sent successfully to", wait: 4)

      expect(ActionMailer::Base.deliveries.count).to eq 1
    end
  end
end

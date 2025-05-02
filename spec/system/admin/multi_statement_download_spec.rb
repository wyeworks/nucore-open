# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Statement Multi-Download", :js, feature_setting: { multiple_statements_download: true } do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }
  let(:item) { create(:setup_item, facility:) }
  let(:accounts) { create_list(:account, 3, :with_account_owner, type: Account.config.statement_account_types.first) }
  let(:orders) do
    accounts.map { |account| create(:complete_order, product: item, account:) }
  end

  let(:order_details) { orders.map(&:order_details).flatten }
  let!(:statement1) { create(:statement, created_at: 9.days.ago, order_details: [order_details.first], account: order_details.first.account, facility:) }
  let!(:statement2) { create(:statement, created_at: 6.days.ago, order_details: [order_details.second], account: order_details.second.account, facility:) }
  let!(:statement3) { create(:statement, created_at: 3.days.ago, order_details: [order_details.last], account: order_details.last.account, facility:) }

  before do
    order_details.each do |detail|
      detail.update(reviewed_at: 1.day.ago)
    end
    login_as director
  end

  describe "facility statements download" do
    before do
      visit facility_statements_path(facility)
    end

    it "shows the download button and checkboxes with feature on" do
      expect(page).to have_button("Download Selected", disabled: true)
      expect(page).to have_css(".js--statement-checkbox", count: 3)
      expect(page).to have_css(".js--select-all-statements", count: 1)
    end

    it "enables download button after selection" do
      expect(page).to have_button("Download Selected", disabled: true)

      first(".js--statement-checkbox").check
      expect(page).to have_button("Download Selected", disabled: false)

      first(".js--statement-checkbox").uncheck
      expect(page).to have_button("Download Selected", disabled: true)
    end

    it "select all works correctly" do
      find(".js--select-all-statements").check

      expect(all(".js--statement-checkbox").all?(&:checked?)).to be true
      expect(page).to have_button("Download Selected", disabled: false)

      find(".js--select-all-statements").uncheck
      expect(all(".js--statement-checkbox").any?(&:checked?)).to be false
      expect(page).to have_button("Download Selected", disabled: true)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Manage Journals" do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:accounts) { create_list(:setup_account, 2) }
  let(:orders) do
    accounts.map { |account| create(:complete_order, product: item, account: account) }
  end

  let(:order_details) { orders.map(&:order_details).flatten }

  before do
    order_details.each do |detail|
      detail.update(reviewed_at: 1.day.ago)
    end
    login_as director
    visit new_facility_journal_path(facility)

    click_on "Select All"
    click_button "Create"
  end

  it "can create a journal with correct info", js: true do
    expect(page).to have_content("Pending Journal")
    expect(find_field("journal_reference").value).to eq(JournalRow.last.ref_2) # Reference field defaults to ref_2 value
  end

  context "with subsidy accounts" do
    let(:accounts) { [create(:subsidy_account, :with_account_owner), create(:subsidy_account, :with_account_owner)] }

    it "can create a journal with correct info", js: true do
      expect(page).to have_content("Pending Journal")
      expect(find_field("journal_reference").value).to eq(JournalRow.last.ref_2)
    end
  end
end

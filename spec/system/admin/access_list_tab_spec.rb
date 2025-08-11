# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples_for "search for a user" do
  context "search for a user", :js do
    let(:user_searchable) { create(:user, first_name: "John", last_name: "Doe", username: "jdoe") }
    let(:user_not_found) { create(:user, first_name: "Jane", last_name: "Holmes", username: "jholmes") }

    before do
      create(:product_user, product:, user: user_not_found)
      create(:product_user, product:, user: user_searchable)
      visit polymorphic_path([:manage, facility, product])
      click_link "Access List"
    end

    it "searches for users by first name" do
      fill_in "access_list_search", with: "John"
      click_button "Search"
      wait_for_ajax
      expect(page).to have_content(user_searchable.last_first_name)
      expect(page).to_not have_content(user_not_found.last_first_name)
    end

    it "searches for users by last name" do
      fill_in "access_list_search", with: "Doe"
      click_button "Search"
      wait_for_ajax
      expect(page).to have_content(user_searchable.last_first_name)
      expect(page).to_not have_content(user_not_found.last_first_name)
    end

    it "searches for users by username" do
      fill_in "access_list_search", with: "jdoe"
      click_button "Search"
      wait_for_ajax
      expect(page).to have_content(user_searchable.last_first_name)
      expect(page).to_not have_content(user_not_found.last_first_name)
    end

    it "searches for users by first name (case insensitive)" do
      fill_in "access_list_search", with: "john"
      click_button "Search"
      wait_for_ajax
      expect(page).to have_content(user_searchable.last_first_name)
      expect(page).to_not have_content(user_not_found.last_first_name)
    end
  end
end

RSpec.describe "Access List Tab for various product types", :js do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let!(:user) { create(:user, username: "ddavidson") }

  before(:each) do
    create(:product_user, product: product, user: user)
    login_as director
    visit polymorphic_path([:manage, facility, product])
    click_link "Access List"
  end

  context "with an instrument" do
    let(:product) { create(:setup_instrument, requires_approval: true, facility: facility) }

    it "is accessible" do
      skip "Accessibility tests temporarily disabled during Bootstrap 2->3 migration"
      expect(page).to be_axe_clean
    end

    it "renders the page" do
      expect(page.current_path).to eq polymorphic_path([facility, product, :users])
    end

    it_behaves_like "search for a user"
  end

  context "with an item" do
    let(:product) { create(:setup_item, requires_approval: true, facility: facility) }

    it "is accessible" do
      skip "Accessibility tests temporarily disabled during Bootstrap 2->3 migration"
      expect(page).to be_axe_clean
    end

    it "renders the page" do
      expect(page.current_path).to eq polymorphic_path([facility, product, :users])
    end

    it_behaves_like "search for a user"
  end

  context "with a service" do
    let(:product) { create(:setup_service, requires_approval: true, facility: facility) }

    it "is accessible" do
      skip "Accessibility tests temporarily disabled during Bootstrap 2->3 migration"
      expect(page).to be_axe_clean
    end

    it "renders the page" do
      expect(page.current_path).to eq polymorphic_path([facility, product, :users])
    end

    it_behaves_like "search for a user"
  end

  context "with a timed service" do
    let(:product) { create(:setup_timed_service, requires_approval: true, facility: facility) }

    it "is accessible" do
      skip "Accessibility tests temporarily disabled during Bootstrap 2->3 migration"
      expect(page).to be_axe_clean
    end

    it "renders the page" do
      expect(page.current_path).to eq polymorphic_path([facility, product, :users])
    end

    it_behaves_like "search for a user"
  end
end

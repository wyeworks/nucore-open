# frozen_string_literal: true

require "rails_helper"

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
      expect(page).to be_axe_clean
    end

    it "renders the page" do
      expect(page.current_path).to eq polymorphic_path([facility, product, :users])
    end
  end

  context "with an item" do
    let(:product) { create(:setup_item, requires_approval: true, facility: facility) }

    it "is accessible" do
      expect(page).to be_axe_clean
    end

    it "renders the page" do
      expect(page.current_path).to eq polymorphic_path([facility, product, :users])
    end
  end

  context "with a service" do
    let(:product) { create(:setup_service, requires_approval: true, facility: facility) }

    it "is accessible" do
      expect(page).to be_axe_clean
    end

    it "renders the page" do
      expect(page.current_path).to eq polymorphic_path([facility, product, :users])
    end
  end

  context "with a timed service" do
    let(:product) { create(:setup_timed_service, requires_approval: true, facility: facility) }

    it "is accessible" do
      expect(page).to be_axe_clean
    end

    it "renders the page" do
      expect(page.current_path).to eq polymorphic_path([facility, product, :users])
    end
  end
end

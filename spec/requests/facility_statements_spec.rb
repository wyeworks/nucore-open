# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Statements" do
  let(:facility) { create(:setup_facility) }
  let(:product) { create(:setup_item, facility:) }
  let(:order) { create(:setup_order, product:) }
  let(:order_detail) { order.order_details.first }
  let(:statement) { create(:statement, facility:) }

  before do
    statement.add_order_detail(order_detail)
    statement.save!
  end

  describe "index" do
    before { login_as create(:user, :administrator) }

    it "shows statement view link on index" do
      get facility_statements_path(facility)

      expect(page).to(
        have_link("View", href: facility_statement_path(facility, statement))
      )
    end
  end

  describe "show" do
    before { login_as create(:user, :administrator) }

    it "shows statements orders" do
      get facility_statement_path(facility, statement)

      expect(page).to have_content(order_detail.order_number)
    end
  end
end

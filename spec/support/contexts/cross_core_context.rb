# frozen_string_literal: true

RSpec.shared_context "cross core orders" do

  # Facility 1 has cross core orders with Facility 2 but NOT Facility 3
  # This is the "Current Facility"
  let(:facility) { create(:setup_facility) }
  let(:facility_administrator) { create(:user, :facility_administrator, facility:) }
  let(:item) { create(:setup_item, facility:) }
  let(:item2) { create(:setup_item, facility:) }
  let(:accounts) { create_list(:setup_account, 2) }
  let!(:originating_order_facility1) { create(:purchased_order, product: item, account: accounts.first, cross_core_project:) }
  let!(:not_a_cross_core_order_facility1) { create(:purchased_order, product: item, account: accounts.first) }

  # Facility 2 has cross core orders with both Facility 1 and Facility 3
  let(:facility2) { create(:setup_facility) }
  let(:facility2_item) { create(:setup_item, facility: facility2) }
  let(:facility2_item2) { create(:setup_item, facility: facility2) }
  let!(:originating_order_facility2) { create(:purchased_order, product: facility2_item, account: accounts.first, cross_core_project: cross_core_project2) }

  # Facility 3 has cross core orders ONLY with Facility 2
  let(:facility3) { create(:setup_facility) }
  let(:facility3_item) { create(:setup_item, facility: facility3) }
  let!(:originating_order_facility3) { create(:purchased_order, product: facility3_item, account: accounts.first, cross_core_project: cross_core_project3) }

  # Create the cross core project records
  let(:cross_core_project) { create(:project, facility:, name: "#{facility.abbreviation}-1") }
  let(:cross_core_project2) { create(:project, facility: facility2, name: "#{facility2.abbreviation}-2") }
  let(:cross_core_project3) { create(:project, facility: facility3, name: "#{facility3.abbreviation}-3") }

  # Create the cross core orders and add them to the relevant projects
  let!(:cross_core_orders) do
    [
      create(:purchased_order, cross_core_project:, product: facility2_item, account: accounts.last),
      create(:purchased_order, cross_core_project:, product: facility3_item, account: accounts.last),
      create(:purchased_order, cross_core_project: cross_core_project2, product: item, account: accounts.last),
      create(:purchased_order, cross_core_project: cross_core_project2, product: facility3_item, account: accounts.last),
      # cross_core_project3 has no order details from facility 1
      create(:purchased_order, cross_core_project: cross_core_project3, product: facility2_item2, account: accounts.last),
    ]
  end
end

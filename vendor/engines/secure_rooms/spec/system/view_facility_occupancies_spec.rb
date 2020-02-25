# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Viewing Occupancies" do
  let(:facility) { create(:setup_facility) }
  let(:secure_room) { create(:secure_room, facility: facility) }
  let(:facility_director) { create(:user, :facility_director, facility: facility) }
  before { login_as facility_director }

  context "with no in-progress occupancies" do
    it "shows no occupancies" do
      visit facility_occupancies_path(facility)

      expect(current_path).to eq(facility_occupancies_path(facility))
      expect(page).to have_content("There are no \"In Process\" occupancies.")
    end
  end

  context "with occupancy" do
    let!(:policy) { create(:secure_room_price_policy, product: secure_room, usage_rate: 60, price_group: order_detail.account.price_groups.first) }
    let(:order) { create(:purchased_order, product: secure_room) }
    let!(:order_detail) { order.order_details.first }

    context "with an active occupancy" do
      let!(:active_occupancy) do
        create(
          :occupancy,
          :active,
          user: order_detail.user,
          secure_room: secure_room,
          order_detail: order_detail,
          account: order_detail.account,
        )
      end

      it "shows the order details" do
        visit facility_occupancies_path(facility)

        expect(current_path).to eq(facility_occupancies_path(facility))
        within(".occupancies") do
          expect(page).to have_content(active_occupancy.order_detail.id)
          expect(page).to have_content(active_occupancy.user.full_name)
          expect(page).to have_content(I18n.l(active_occupancy.entry_at, format: :usa))
          expect(page).to have_content(active_occupancy.secure_room.name)
        end
      end
    end

    context "with an orphaned occupancy" do
      let!(:problem_occupancy) do
        create(
          :occupancy,
          :orphan,
          user: order_detail.user,
          secure_room: secure_room,
          order_detail: order_detail,
          account: order_detail.account,
        )
      end

      before { order_detail.complete! }

      it "shows the order details" do
        visit show_problems_facility_occupancies_path(facility)

        expect(current_path).to eq(show_problems_facility_occupancies_path(facility))
        # TODO: Update specs after page is updated
        expect(page).to have_link(problem_occupancy.order_detail.id.to_s)
        expect(page).to have_content(problem_occupancy.user.full_name)
        expect(page).to have_content(problem_occupancy.secure_room.name)
        expect(page).to have_content("Missing Exit")
      end
    end

    context "with a missing price-policy occupancy" do
      let!(:occupancy) do
        create(
          :occupancy,
          :complete,
          user: order_detail.user,
          secure_room: secure_room,
          order_detail: order_detail,
          account: order_detail.account,
        )
      end

      before do
        secure_room.price_policies.destroy_all
        order_detail.backdate_to_complete! occupancy.exit_at
      end

      it "can mass assign price policies" do
        visit show_problems_facility_occupancies_path(facility)

        expect(page).to have_content(order_detail.id)
        expect(page).to have_content("Missing Price Policy")

        create(:secure_room_price_policy, product: secure_room, price_group: order_detail.user.price_groups.first)

        click_link "Assign Price Policies"

        expect(order_detail.reload).not_to be_problem
        expect(current_path).to eq(show_problems_facility_occupancies_path(facility))
        expect(page).not_to have_link(occupancy.order_detail.id.to_s)
      end
    end
  end
end

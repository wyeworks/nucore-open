# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe ReconcilliationsController do
  let(:user) { FactoryBot.create(:user) }
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:item) { FactoryBot.create(:item, facility: facility) }
  let(:account) { FactoryBot.create(:setup_account, owner: user) }
  let(:order_detail) { place_and_complete_item_order(user, facility, account) }

  before :each do
    order_detail.change_status! OrderStatus.reconciled
  end

  describe "DELETE to :destroy" do
    context "for an administrator" do
      let(:admin) { FactoryBot.create(:user, :administrator) }

      before :each do
        sign_in admin
        delete :destroy, params: { facility_id: facility.url_name, order_id: order_detail.order.id, order_detail_id: order_detail.id }
      end

      it "changes the order detail’s status to complete" do
        expect(order_detail.reload.state).to eq "complete"
      end

      it "redirects the user to the facility transactions page" do
        expect(response).to redirect_to facility_transactions_path(facility)
      end
    end

    context "for a user that is not an administrator" do
      let(:director) { create(:user, :facility_director, facility: facility) }

      before :each do
        sign_in director
      end

      it "does not allow the action" do
        expect { delete :destroy, params: { facility_id: facility.url_name, order_id: order_detail.order.id, order_detail_id: order_detail.id } }.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end

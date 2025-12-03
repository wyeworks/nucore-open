# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChartStringReassignmentForm do
  describe "#available_accounts" do
    subject(:form) { ChartStringReassignmentForm.new(order_details) }

    context "User has accounts in multiple facilities" do
      let(:facility_account_type) { Account.config.facility_account_types.first&.underscore }
      let(:current_facility_account) do
        setup_account(facility_account_type, current_facility, user)
      end
      let(:current_facility) { create(:facility) }
      let(:order) { create(:purchased_order, product: product) }
      let(:order_details) { [create(:order_detail, order: order, product: product)] }
      let(:other_facility) { create(:facility) }
      let(:product) { create(:setup_item) }
      let(:user) { create(:user) }

      before { skip if facility_account_type.blank? }

      before :each do
        setup_account(facility_account_type, other_facility, user)

        order.update(facility_id: current_facility.id, user_id: user.id)

        order_details.each do |order_detail|
          order_detail.update_attribute(:account_id, current_facility_account.id)
        end
      end

      it "limits accounts to those available in the current facility" do
        expect(form.available_accounts).to eq [current_facility_account]
      end
    end
  end
end

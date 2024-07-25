# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order do
  subject(:order) { create(:setup_order, product: item) }
  let(:item) { create(:setup_item) }
  let(:project_id) { create(:project, facility: order.facility).id }

  describe "#project_id=" do
    before(:each) do
      order.project_id = project_id
      order.save
    end

    context "when setting it to nil" do
      let(:project_id) { nil }

      it "sets the project_id on its order_details to nil" do
        order.order_details.each do |order_detail|
          expect(order_detail.project_id).to be_blank
        end
      end
    end

    context "when setting it to a project_id" do
      context "that is valid for the facility" do
        it "sets this project_id on its order_details" do
          order.order_details.each do |order_detail|
            expect(order_detail.project_id).to eq(project_id)
          end
        end
      end

      context "that is invalid for the facility" do
        let(:project_id) { create(:project).id }

        it "fails to set project_id on the order_details" do
          order.reload.order_details.each do |order_detail|
            expect(order_detail.project_id).to be_blank
          end
        end
      end
    end
  end
end

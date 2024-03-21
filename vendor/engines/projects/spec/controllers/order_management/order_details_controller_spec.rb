# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderManagement::OrderDetailsController do
  let(:order_detail) { order.order_details.first }
  let(:facility) { order.facility }
  let(:item) { FactoryBot.create(:setup_item) }
  let(:order) { FactoryBot.create(:purchased_order, product: item) }
  let(:active_project) { FactoryBot.create(:project, facility: facility) }
  let(:inactive_project) { FactoryBot.create(:project, :inactive, facility: facility) }

  describe "PUT #update" do
    def perform_request
      put :update, params: {
        facility_id: facility.url_name,
        order_id: order.id,
        id: order_detail.id,
        order_detail: { project_id: project_id },
      }
    end

    before(:each) do
      sign_in FactoryBot.create(:user, :administrator)
      perform_request
      order_detail.reload
    end

    context "when the order_detail had no project" do
      context "and it updates specifying a project" do
        context "that is associated with the same facility" do
          context "and is active" do
            let(:project_id) { active_project.id }
            it { expect(order_detail.project_id).to eq(project_id) }
          end

          context "and is inactive" do
            let(:project_id) { inactive_project.id }
            it { expect(order_detail.project_id).to be_blank }
          end
        end

        context "that is associated with a different facility" do
          let(:project_id) { FactoryBot.create(:project).id }
          it { expect(order_detail.project_id).to eq(project_id) }
        end
      end

      context "and it updates specifying no project" do
        let(:project_id) { nil }
        it { expect(order_detail.project_id).to be_blank }
      end
    end

    context "when the order_detail had a project" do
      context "that is currently active" do
        before { order_detail.update_attribute(:project_id, active_project.id) }

        context "and it updates to a project" do
          context "that is associated with the same facility" do
            context "and is active" do
              let(:project_id) { active_project.id }
              it { expect(order_detail.project_id).to eq(project_id) }
            end

            context "and is inactive" do
              let(:project_id) { inactive_project.id }
              it { expect(order_detail.project_id).to eq(active_project.id) }
            end
          end

          context "that is associated with a different facility" do
            let(:project_id) { FactoryBot.create(:project).id }
            it { expect(order_detail.project_id).to eq(active_project.id) }
          end
        end
      end

      context "that is currently inactive" do
        before(:each) do
          order_detail.update_attribute(:project_id, inactive_project.id)
        end

        context "and it updates using this same inactive project_id" do
          let(:project_id) { inactive_project.id }
          it { expect(order_detail.project_id).to eq(inactive_project.id) }
        end
      end
    end
  end
end

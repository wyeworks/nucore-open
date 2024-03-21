# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::OrderDetailExtension do
  subject(:order_detail) { order.order_details.first }
  let(:facility) { order.facility }
  let(:item) { FactoryBot.create(:setup_item) }
  let(:order) { FactoryBot.create(:setup_order, product: item) }
  let(:project) { FactoryBot.create(:project, facility: facility) }

  context "validations" do
    it "can belong_to a Project" do
      is_expected
        .to belong_to(:project)
        .with_foreign_key(:project_id)
        .inverse_of(:order_details)
    end

    describe "Facility scoping" do
      subject(:order_detail) { order.order_details.first }

      before { order_detail.update_attribute(:project_id, project.id) }

      context "when the Project belongs to the same facility as the Order" do
        it { is_expected.to be_valid }
      end

      context "when the Project belongs to a different facility than the Order" do
        let(:facility) { FactoryBot.create(:facility) }

        it { is_expected.to be_valid }
      end
    end

    context "when the project is inactive" do
      before { order_detail.update_attribute(:project_id, project.id) }

      context "and the order_detail was already associated with it" do
        before(:each) do
          project.update_attribute(:active, false)
          order_detail.project_id = project.id
        end

        it { is_expected.to be_valid }
      end

      context "and the order_detail was not already associated with it" do
        let(:inactive_project) do
          FactoryBot.create(:project, :inactive, facility: facility)
        end

        it "is invalid" do
          order_detail.project_id = inactive_project.id
          is_expected.not_to be_valid
          expect(order_detail.errors[:project_id])
            .to include("The project is inactive")
        end
      end
    end
  end

  describe "#selectable_projects" do
    subject(:order_detail) { order.order_details.first }

    context "when there are no active projects for the associated facility" do
      before(:each) do
        FactoryBot.create(:project, :inactive, facility: order_detail.facility)
      end

      it { expect(order_detail.selectable_projects).to be_empty }
    end

    context "when there are active projects for the associated facility" do
      let(:active_projects) { FactoryBot.create_list(:project, 3, facility: facility) }
      let(:inactive_project) { FactoryBot.create(:project, :inactive, facility: facility) }
      let!(:all_projects) { active_projects + [inactive_project] }

      before { order_detail.update_attribute(:project_id, project_id) }

      context "and the order_detail has an inactive project" do
        let(:project_id) { inactive_project.id }

        it "includes the inactive project in the list" do
          expect(order_detail.selectable_projects)
            .to match_array(active_projects + [inactive_project])
        end
      end

      context "and the order_detail has no project selected" do
        let(:project_id) { nil }

        it "returns all active projects for the facility" do
          expect(order_detail.selectable_projects)
            .to match_array(active_projects)
        end
      end

      context "when the order_detail has an active project selected" do
        let(:project_id) { active_projects.first.id }

        it "returns all active projects for the facility" do
          expect(order_detail.selectable_projects)
            .to match_array(active_projects)
        end
      end
    end
  end
end

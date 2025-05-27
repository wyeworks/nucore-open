# frozen_string_literal: true

require "rails_helper"

# TODO: These specs are incomplete and document existing behavior

RSpec.describe OrderDetailBatchUpdater do
  subject(:updater) do
    described_class.new(
      [order_detail.id],
      facility,
      user,
      params,
      record_type,
    )
  end

  let(:assigned_user_id) { "" }
  let(:facility) { order.facility }
  let(:item) { FactoryBot.create(:setup_item) }
  let(:order) { FactoryBot.create(:purchased_order, product: item) }
  let(:order_detail) { order.order_details.first }
  let(:order_status_id) { "" }
  let(:params) do
    { assigned_user_id: assigned_user_id, order_status_id: order_status_id }
  end
  let(:user) { FactoryBot.create(:user) }

  describe "#update!" do
    shared_examples_for "batch updating" do
      context "when assigned_user_id is already set" do
        let(:assigned_user) { create(:user) }
        before do
          order_detail.update_attribute(:assigned_user, assigned_user)
        end

        context "and the assigned_user_id parameter is blank" do
          it "does not change the assigned_user_id" do
            expect { updater.update! }
              .not_to change { order_detail.reload.assigned_user_id }
              .from(assigned_user.id)
          end

          it "returns a no-changes-required note" do
            expect(updater.update!).to eq(notice: "No changes were required")
          end
        end

        context "and the assigned_user_id parameter is a new value" do
          let(:new_assigned_user) { create(:user) }
          let(:assigned_user_id) { new_assigned_user.id.to_s }

          it "updates assigned_user_id to the new value" do
            expect { updater.update! }
              .to change { order_detail.reload.assigned_user_id }
              .from(assigned_user.id)
              .to(assigned_user_id.to_i)
          end

          it "returns a successful update note" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end

        context "and the assigned_user_id parameter is the same value" do
          let(:assigned_user_id) { assigned_user.id.to_s }

          it "does not change the assigned_user_id" do
            expect { updater.update! }
              .not_to change { order_detail.reload.assigned_user_id }
              .from(assigned_user.id)
          end

          it "returns a successful update note (despite nothing changing)" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end

        context "and the assigned_user_id parameter is set to 'unassign'" do
          let(:assigned_user_id) { "unassign" }

          it "changes the assigned_user_id to nil" do
            expect { updater.update! }
              .to change { order_detail.reload.assigned_user_id }
              .from(assigned_user.id)
              .to(nil)
          end

          it "returns a successful update note" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end
      end

      context "when assigned_user_id is not set" do
        context "and the assigned_user_id parameter is blank" do
          it "does not change the assigned_user_id from nil" do
            expect { updater.update! }
              .not_to change { order_detail.reload.assigned_user_id }
              .from(nil)
          end

          it "returns a no-changes-required note" do
            expect(updater.update!).to eq(notice: "No changes were required")
          end
        end

        context "and the assigned_user_id parameter is a new value" do
          let(:assigned_user_id) { user.id.to_s }

          it "updates assigned_user_id to the new value" do
            expect { updater.update! }
              .to change { order_detail.reload.assigned_user_id }
              .from(nil)
              .to(user.id)
          end

          context "when the assignment notifications are on", feature_setting: { order_assignment_notifications: true } do
            it "sends the assignee one notification" do
              expect { updater.update! }.to(
                enqueue_mail(OrderAssignmentMailer, :notify_assigned_user)
              )
            end
          end

          context "when the assignment notifications are off", feature_setting: { order_assignment_notifications: false } do
            it "sends no notifications" do
              expect { updater.update! }.not_to enqueue_mail
            end
          end

          it "returns a successful update note" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end

        context "and the assigned_user_id parameter is set to 'unassign'" do
          let(:assigned_user_id) { "unassign" }

          it "does not change the assigned_user_id from nil" do
            expect { updater.update! }
              .not_to change { order_detail.reload.assigned_user_id }
              .from(nil)
          end

          it "returns a successful update note (despite nothing changing)" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end
      end

      context "when order_status_id is already set" do
        let(:new_status_id) { OrderStatus.new_status.id }
        let(:in_process_status_id) { OrderStatus.in_process.id }
        let(:canceled_status_id) { OrderStatus.canceled.id }
        before(:each) do
          order_detail.update_attribute(:order_status_id, in_process_status_id)
        end

        context "and the order_status_id parameter is blank" do
          it "does not change the order_status_id" do
            expect { updater.update! }
              .not_to change { order_detail.reload.order_status_id }
              .from(in_process_status_id)
          end

          it "returns a no-changes-required note" do
            expect(updater.update!).to eq(notice: "No changes were required")
          end
        end

        context "and the order_status_id parameter is a new value" do
          let(:order_status_id) { new_status_id }

          it "updates order_status_id to the new value" do
            expect { updater.update! }
              .to change { order_detail.reload.order_status_id }
              .from(in_process_status_id)
              .to(new_status_id)
          end

          it "returns a successful update note" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end

        context "and the order_status_id parameter is the same value" do
          let(:order_status_id) { in_process_status_id }

          it "does not change the order_status_id" do
            expect { updater.update! }
              .not_to change { order_detail.reload.order_status_id }
              .from(in_process_status_id)
          end

          it "returns a successful update note (despite nothing changing)" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end

        context "and the order is canceled" do
          let(:order_status_id) { canceled_status_id }

          it "updates order_status_id to the new value" do
            expect { updater.update! }
              .to change { order_detail.reload.order_status_id }
              .from(in_process_status_id)
              .to(canceled_status_id)
          end

          it "sets canceled info" do
            expect { updater.update! }
              .to change { order_detail.reload.canceled_by_user }
              .from(nil)
              .to(user)
          end

          it "returns a successful update note" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end
      end

      context "when order_status_id is not set" do
        it { expect(updater.update!).to eq(notice: "No changes were required") }
      end
    end

    context "when associated with Orders" do
      let(:record_type) { "orders" }

      it_behaves_like "batch updating"
    end

    context "when associated with Reservations" do
      let(:record_type) { "reservations" }

      it_behaves_like "batch updating"
    end

    context "project_id" do
      subject(:updater) do
        described_class.new(
          [order_detail.id],
          facility,
          user,
          { project_id: project_id },
          record_type,
        )
      end

      shared_examples_for "batch updating project_id" do
        let(:other_project) { FactoryBot.create(:project, facility: facility) }

        context "when project_id is already set" do
          let(:existing_project) { FactoryBot.create(:project, facility: facility) }

          before { order_detail.update_attribute(:project_id, existing_project.id) }

          context "and the project_id parameter is blank" do
            let(:project_id) { "" }

            it "does not change the project_id" do
              expect { updater.update! }
                .not_to change { order_detail.reload.project_id }
                .from(existing_project.id)
            end
          end

          context "and the project_id parameter is a new value" do
            let(:project_id) { other_project.id }

            it "changes the project_id to the new value" do
              expect { updater.update! }
                .to change { order_detail.reload.project_id }
                .from(existing_project.id)
                .to(other_project.id)
            end
          end

          context "and the project_id parameter is the same value" do
            let(:project_id) { existing_project.id }

            it "does not change the project_id" do
              expect { updater.update! }
                .not_to change { order_detail.reload.project_id }
                .from(existing_project.id)
            end
          end

          context "and the project_id parameter is set to 'unassign'" do
            let(:project_id) { "unassign" }

            it "changes the project_id to nil" do
              expect { updater.update! }
                .to change { order_detail.reload.project_id }
                .from(existing_project.id)
                .to(nil)
            end
          end
        end

        context "when project_id is not set" do
          context "and the project_id parameter is blank" do
            let(:project_id) { "" }

            it "does not change the project_id from nil" do
              expect { updater.update! }
                .not_to change { order_detail.reload.project_id }
                .from(nil)
            end
          end

          context "and the project_id parameter is a new value" do
            let(:project_id) { other_project.id }

            it "updates project_id to the new value" do
              expect { updater.update! }
                .to change { order_detail.reload.project_id }
                .from(nil)
                .to(other_project.id)
            end
          end

          context "and the project_id parameter is set to 'unassign'" do
            let(:project_id) { "unassign" }

            it "does not change the project_id from nil" do
              expect { updater.update! }
                .not_to change { order_detail.reload.project_id }
                .from(nil)
            end
          end
        end
      end

      context "when associated with Orders" do
        let(:record_type) { "orders" }

        it_behaves_like "batch updating project_id"
      end

      context "when associated with Reservations" do
        let(:record_type) { "Reservations" }

        it_behaves_like "batch updating project_id"
      end
    end
  end
end

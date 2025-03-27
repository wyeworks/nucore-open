# frozen_string_literal: true

RSpec.shared_examples_for "it supports order_detail POST #batch_update" do
  context "POST #batch_update" do
    before do
      @method = :post
      @action = :batch_update
    end

    it_should_allow_operators_only :redirect

    context "when batch-assigning facility staff" do
      let(:admin) { FactoryBot.create(:user, :facility_administrator, facility: facility) }
      let(:assignee) { FactoryBot.create(:user, :staff, facility: facility) }
      let(:orders) { FactoryBot.create_list(:purchased_order, 3, product: product) }
      let(:order_details) { orders.flat_map(&:order_details) }

      before do
        @params[:assigned_user_id] = assignee.id.to_s
        @params[:order_detail_ids] = order_details.map(&:id).map(&:to_s)
        sign_in admin
      end

      it "updates assigned_user_id attributes" do
        expect { do_request }
          .to change { order_details.map(&:reload).map(&:assigned_user_id) }
          .from([nil, nil, nil])
          .to(Array.new(3) { assignee.id })
      end

      context "when assignment notifications are on", feature_setting: { order_assignment_notifications: true } do
        it "sends the assignee one notification" do
          expect { do_request }.to have_enqueued_mail(
            OrderAssignmentMailer, :notify_assigned_user
          )
        end
      end

      context "when assignment notifications are off", feature_setting: { order_assignment_notifications: false } do
        it "sends no notifications" do
          expect { do_request }.not_to have_enqueued_mail
        end
      end
    end
  end
end

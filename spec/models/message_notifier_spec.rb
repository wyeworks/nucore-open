require "spec_helper"

describe MessageNotifier do
  subject { MessageNotifier.new(user, ability, facility) }
  let(:ability) { Object.new.extend(CanCan::Ability) }
  let(:facility) { order.facility }
  let(:order) { create(:purchased_order, product: product) }
  let(:order_detail) { order.order_details.first }
  let(:product) { create(:instrument_requiring_approval) }
  let(:user) { create(:user) }

  def create_merge_notification
    merge_to_order = order.dup
    merge_to_order.save!
    order.update_attribute(:merge_with_order_id, merge_to_order.id)
    MergeNotification.create_for!(user, order_detail.reload)
  end

  def set_problem_order
    order_detail.update_attribute(:state, :complete)
    order_detail.set_problem_order
  end

  shared_examples_for "there are no messages" do
    it "has no messages of any kind" do
      expect(subject).not_to be_messages
      expect(subject).not_to be_notifications
      expect(subject).not_to be_problem_order_details
      expect(subject).not_to be_problem_reservation_order_details
      expect(subject.message_count).to eq(0)
      expect(subject.notifications.count).to eq(0)
      expect(subject.problem_order_details.count).to eq(0)
      expect(subject.problem_reservation_order_details.count).to eq(0)
      expect(subject.training_requests.count).to eq(0)
    end
  end

  shared_examples_for "there is one overall message" do
    it "has one message" do
      expect(subject).to be_messages
      expect(subject.message_count).to eq(1)
    end
  end

  context "when no active notifications, training requests, disputed or problem orders exist" do
    it_behaves_like "there are no messages"
  end

  context "when an active notification exists" do
    before { create_merge_notification }

    shared_examples_for "the user may view notifications" do
      it_behaves_like "there is one overall message"

      it "has one notification" do
        expect(subject).to be_notifications
        expect(subject.notifications.count).to eq(1)
      end

      context "when not scoped to a facility" do
        subject { MessageNotifier.new(user, ability, nil) }

        it_behaves_like "there is one overall message"

        it "has one notification" do
          expect(subject).to be_notifications
          expect(subject.notifications.count).to eq(1)
        end
      end
    end

    context "and the user is an operator" do
      let(:user) { create(:user, :staff) }

      it_behaves_like "the user may view notifications"
    end

    context "and the user is an administrator" do
      let(:user) { create(:user, :administrator) }

      it_behaves_like "the user may view notifications"
    end

    context "and the user may not view notifications" do
      it_behaves_like "there are no messages"
    end
  end

  context "when a disputed order detail exists" do
    before { order_detail.update_attribute(:dispute_at, 1.day.ago) }

    context "and the user can access disputed order details" do
      before { ability.can(:disputed_orders, Facility) }

      it_behaves_like "there is one overall message"

      it "has one disputed order detail message" do
        expect(subject).to be_order_details_in_dispute
        expect(subject.order_details_in_dispute.count).to eq(1)
      end

      context "when not scoped to a facility" do
        subject { MessageNotifier.new(user, ability, nil) }

        it_behaves_like "there are no messages"
      end
    end

    context "and the user cannot access disputed order details" do
      it_behaves_like "there are no messages"
    end
  end

  context "when a problem order detail exists" do
    let(:product) { create(:setup_item) }

    before(:each) { set_problem_order }

    context "and the user can access problem orders" do
      before { ability.can(:show_problems, Order) }

      it_behaves_like "there is one overall message"

      it "has one problem order detail message" do
        expect(subject).to be_problem_order_details
        expect(subject.problem_order_details.count).to eq(1)
      end

      context "when not scoped to a facility" do
        subject { MessageNotifier.new(user, ability, nil) }

        it_behaves_like "there are no messages"
      end
    end

    context "and the user cannot access problem orders" do
      it_behaves_like "there are no messages"
    end
  end

  context "when a problem reservation order detail exists" do
    before(:each) { set_problem_order }

    context "and the user can access problem reservations" do
      before { ability.can(:show_problems, Reservation) }

      it_behaves_like "there is one overall message"

      it "has one problem reservation order detail message" do
        expect(subject).to be_problem_reservation_order_details
        expect(subject.problem_reservation_order_details.count).to eq(1)
      end

      context "when not scoped to a facility" do
        subject { MessageNotifier.new(user, ability, nil) }

        it_behaves_like "there are no messages"
      end
    end

    context "and the user cannot access problem reservations" do
      it_behaves_like "there are no messages"
    end
  end

  context "when a training request exists" do
    before { create(:training_request, product: product) }

    context "and the user can manage training requests" do
      before { ability.can(:manage, TrainingRequest) }

      it_behaves_like "there is one overall message"

      it "has one training request message" do
        expect(subject).to be_training_requests
        expect(subject.training_requests.count).to eq(1)
      end

      context "when not scoped to a facility" do
        subject { MessageNotifier.new(user, ability, nil) }

        it_behaves_like "there are no messages"
      end
    end

    context "and the user cannot manage training requests" do
      it_behaves_like "there are no messages"
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AccessHandlers::OrderHandler, type: :service do
  let(:user) { create(:user, card_number: "123456") }
  let(:secure_room) { create(:secure_room, :with_schedule_rule, :with_base_price) }
  let(:account) { create(:nufs_account, :with_account_owner, owner: user) }
  let!(:card_reader) { create :card_reader, secure_room: secure_room }

  before do
    secure_room.product_users.create!(user: user, approved_by: 0)
  end

  describe "#process" do
    context "with an orderable occupancy" do
      let(:occupancy) do
        create(:occupancy, :active, user: user, secure_room: secure_room, account: account)
      end

      it "creates an order" do
        expect { described_class.process(occupancy) }
          .to change(Order, :count).by(1)
      end

      it "creates an order detail" do
        expect { described_class.process(occupancy) }
          .to change(OrderDetail, :count).by(1)
      end

      describe "the order" do
        subject(:order) { described_class.process(occupancy) }

        it { is_expected.to be_purchased }

        it "sets ordered_at" do
          expect(order.order_details.map(&:ordered_at)).to all(be_present)
        end

        it "stores the associations from the Occupancy" do
          expect(order.account).to eq account
          expect(order.user).to eq user
          expect(order.facility).to eq card_reader.facility
          expect(order.created_by_user).to eq user
        end
      end

      describe "the order detail" do
        subject(:order_detail) { described_class.process(occupancy).order_details.first }

        it { is_expected.to be_new }

        it "sets order_status" do
          expect(order_detail.order_status).to eq OrderStatus.new_status
        end

        it "stores the associations from the Occupancy" do
          expect(order_detail.product).to eq card_reader.secure_room
          expect(order_detail.occupancy).to eq occupancy
          expect(order_detail.created_by_user).to eq user
        end
      end

      context "when completing the occupancy" do
        let(:occupancy) do
          create(
            :occupancy,
            :complete,
            user: user,
            secure_room: secure_room,
            account: account,
          )
        end

        describe "order_detail" do
          subject(:order_detail) { described_class.process(occupancy).order_details.first }

          it { is_expected.to be_complete }
          it { is_expected.to be_fulfilled_at }
          it { is_expected.not_to be_problem }

          it "has price information" do
            expect(order_detail.price_policy).to be_present
            expect(order_detail.cost).to be_present
          end
        end

        context "when the user scans out after the schedules permits" do
          before { allow_any_instance_of(ScheduleRule).to receive(:cover?).and_return false }

          subject(:order_detail) { described_class.process(occupancy).order_details.first }

          it { is_expected.to be_complete }
        end
      end

      context "when orphaned" do
        let(:occupancy) do
          create(
            :occupancy,
            :orphan,
            user: user,
            secure_room: secure_room,
            account: account,
          )
        end

        subject(:order_detail) { described_class.process(occupancy).order_details.first }

        it { is_expected.to be_complete }
        it { is_expected.to be_problem }

        it "triggers an email" do
          expect { described_class.process(occupancy) }.to change(ActionMailer::Base.deliveries, :count).by(1)
        end
      end
    end

    context "without an occupancy account" do
      let(:occupancy) do
        create(:occupancy, :active, user: user, secure_room: card_reader.secure_room, account: account)
      end

      context "when the user is expected to pay for access" do
        it "creates an order" do
          expect { described_class.process(occupancy) }
            .to change(Order, :count).by(1)
        end

        describe "the order" do
          subject(:order) { described_class.process(occupancy) }

          it { is_expected.to be_purchased }

          it "assigns an account to the order" do
            expect(order.account).to eq account
          end
        end
      end

      context "when the user is a facility operator" do
        let(:user) { create :user, :facility_director, facility: card_reader.facility }

        it "does not create an order" do
          expect { described_class.process(occupancy) }
            .not_to change(Order, :count)
        end
      end
    end
  end
end

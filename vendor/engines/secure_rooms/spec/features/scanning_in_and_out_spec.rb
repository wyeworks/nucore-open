# frozen_string_literal: true

require "rails_helper"

# This is intended as an API-level feature spec. It uses the controller testing
# mechanism since Capybara doesn't provide good API testing.
RSpec.describe "Scanning in and out", type: :controller do
  before { @controller = SecureRoomsApi::ScansController.new }

  before do
    name = Rails.application.secrets.secure_rooms_api[:basic_auth_name]
    password = Rails.application.secrets.secure_rooms_api[:basic_auth_password]
    encoded_auth_credentials = ActionController::HttpAuthentication::Basic.encode_credentials(name, password)
    request.env["HTTP_AUTHORIZATION"] = encoded_auth_credentials
  end

  let(:secure_room) { create(:secure_room, :with_schedule_rule, :with_base_price) }
  let!(:in_reader) { create(:card_reader, secure_room: secure_room, ingress: true) }

  let(:user) { create(:user, card_number: "123456") }
  let(:account) { create(:nufs_account, :with_account_owner, owner: user) }
  before { secure_room.product_users.create!(user: user, approved_by: 0) }

  describe "with a room having both in and out" do
    let!(:out_reader) { create(:card_reader, ingress: false, secure_room: secure_room) }

    describe "scanning in" do
      before do
        post :scan, params: {
          card_number: user.card_number,
          reader_identifier: in_reader.card_reader_number,
          controller_identifier: in_reader.control_device_number,
          account_identifier: account.id,
        }
      end

      context "with a paying user" do
        it "creates a new order in purchased state" do
          expect(user.orders).to be_one
          expect(user.orders.first).to be_purchased
        end

        describe "and then scanning out" do
          before do
            post :scan, params: {
              card_number: user.card_number,
              reader_identifier: out_reader.card_reader_number,
              controller_identifier: out_reader.control_device_number,
            }
          end

          it "completes the order and sets pricing" do
            expect(user.order_details).to be_one
            expect(user.order_details.first).to be_complete
            expect(user.order_details.first.price_policy).to be_present
            expect(user.order_details.first.actual_total).to be_present
          end
        end
      end

      context "with a non-paying user" do
        let(:user) { create(:user, :staff, card_number: "123456", facility: secure_room.facility) }

        it "does not create any order" do
          expect(user.orders).to be_blank
        end

        describe "and then scanning out" do
          before do
            post :scan, params: {
              card_number: user.card_number,
              reader_identifier: out_reader.card_reader_number,
              controller_identifier: out_reader.control_device_number,
            }
          end

          it "again does not create any order" do
            expect(user.orders).to be_blank
          end
        end
      end
    end

    describe "scanning out" do
      let!(:account) { create(:nufs_account, :with_account_owner, owner: user) }

      before do
        post :scan, params: {
          card_number: user.card_number,
          reader_identifier: out_reader.card_reader_number,
          controller_identifier: out_reader.control_device_number,
        }
      end

      context "with a paying user" do
        it "creates an order with a problem order detail" do
          expect(user.orders).to be_one
          expect(user.order_details.first).to be_problem
        end
      end

      context "with a non-paying user" do
        let(:user) { create(:user, :staff, card_number: "123456", facility: out_reader.facility) }

        it "does not create any order" do
          expect(user.orders).to be_blank
        end
      end
    end
  end

  describe "with a room having only an entry reader" do
    describe "scanning in" do
      before do
        post :scan, params: {
          card_number: user.card_number,
          reader_identifier: in_reader.card_reader_number,
          controller_identifier: in_reader.control_device_number,
          account_identifier: account.id,
        }
      end

      it "creates a new order in a completed state with pricing" do
        expect(user.order_details).to be_one
        expect(user.order_details.first).to be_complete
        expect(user.order_details.first.price_policy).to be_present
        expect(user.order_details.first.actual_total).to be_present
      end
    end
  end
end

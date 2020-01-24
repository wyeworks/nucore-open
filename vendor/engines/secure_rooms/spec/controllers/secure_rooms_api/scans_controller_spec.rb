# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRoomsApi::ScansController do
  context "scan" do
    before do
      name = Rails.application.secrets.secure_rooms_api[:basic_auth_name]
      password = Rails.application.secrets.secure_rooms_api[:basic_auth_password]
      encoded_auth_credentials = ActionController::HttpAuthentication::Basic.encode_credentials(name, password)
      request.env["HTTP_AUTHORIZATION"] = encoded_auth_credentials
    end

    subject { response }

    let(:card_number) { "123456" }
    let(:secure_room) { create(:secure_room, :with_schedule_rule) }
    let(:card_reader) { create(:card_reader, tablet_token: "TABLETID", secure_room: secure_room, control_device_number: "FF:FF:FF:FF:FF:FF") }
    let(:user) { create(:user, card_number: card_number) }

    describe "negative responses" do
      before do
        post :scan, params: {
          card_number: card_number,
          reader_identifier: card_reader.card_reader_number,
          controller_identifier: card_reader.control_device_number,
        }
      end

      describe "initial deny response" do
        it { is_expected.to have_http_status(:forbidden) }
      end

      describe "not allowed response" do
        context "when card does not exist" do
          let(:card_number) { "789123" }

          it { is_expected.to have_http_status(:forbidden) }
          it "responds with JSON" do
            expect(response.content_type).to eq("application/json")
          end
        end

        context "when card reader does not exist" do
          let(:card_reader) { build(:card_reader) }

          it { is_expected.to have_http_status(:not_found) }
          it "responds with JSON" do
            expect(response.content_type).to eq("application/json")
          end
        end
      end
    end

    describe "positive responses" do
      context "with multiple accounts" do
        let(:accounts) { create_list(:account, 3, :with_account_owner, owner: user) }

        before do
          card_reader.secure_room.update(requires_approval: false)
          allow_any_instance_of(Product).to receive(:can_purchase_order_detail?).and_return(true)

          allow_any_instance_of(User).to receive(:accounts_for_product).and_return(accounts)

          post :scan, params: {
            card_number: user.card_number,
            reader_identifier: card_reader.card_reader_number,
            controller_identifier: card_reader.control_device_number,
            account_identifier: account_identifier,
          }
        end

        context "with account id requested" do
          let(:account_identifier) { accounts.last.id }

          it { is_expected.to have_http_status(:ok) }
        end

        context "with no selection" do
          let(:account_identifier) { nil }

          it { is_expected.to have_http_status(:multiple_choices) }

          it "is expected to contain a list of accounts" do
            expect(JSON.parse(response.body)).to include("accounts")
            expect(JSON.parse(response.body)["accounts"].size).to eq 3
          end

          it "has the tablet token" do
            expect(JSON.parse(response.body)["tablet_identifier"]).to eq("TABLETID")
          end
        end
      end

      describe "with a mis-cased controller ID" do
        before do
          post :scan, params: {
            card_number: user.card_number,
            reader_identifier: card_reader.card_reader_number,
            controller_identifier: card_reader.control_device_number.downcase,
          }
        end

        it { is_expected.not_to have_http_status(:not_found) }
      end
    end
  end
end

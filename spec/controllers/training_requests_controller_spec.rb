# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrainingRequestsController, feature_setting: { training_requests: true, reload_routes: true } do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:product) do
    FactoryBot.create(:setup_item, facility: facility,
                                   requires_approval: true, training_request_contacts: training_request_contacts)
  end
  let(:training_request_contacts) { "test@example.com, test2@example.com" }
  let(:user) { FactoryBot.create(:user) }

  describe "#new" do
    def do_request
      get :new, params: { facility_id: facility.url_name, product_id: product.url_name }
    end

    describe "while not logged in" do
      it "sends the user to sign in" do
        do_request
        expect(response).to redirect_to new_user_session_path
      end
    end

    describe "while logged in" do
      before { sign_in user }

      it "gives access" do
        do_request
        expect(response).to be_successful
      end

      it "has the product" do
        do_request
        expect(assigns[:product]).to eq(product)
      end
    end
  end

  describe "#create" do
    def do_request
      put :create, params: { facility_id: facility.url_name, product_id: product.url_name }
    end

    describe "not logged in" do
      it "sends the user to sign in" do
        do_request
        expect(response).to redirect_to new_user_session_path
      end
    end

    describe "while logged in" do
      before { sign_in user }

      describe "and the user does not already have a request pending" do
        it "creates a new training request" do
          expect { do_request }.to change(TrainingRequest, :count).by(1)
        end

        it "sends an email" do
          expect { do_request }.to change(ActionMailer::Base.deliveries, :count).by(1)
        end

        describe "no contacts are assigned" do
          let(:training_request_contacts) { "" }
          it "does not send an email" do
            expect { do_request }.not_to change(ActionMailer::Base.deliveries, :count)
          end
        end
      end

      describe "but the user has a request pending already" do
        before { TrainingRequest.create!(user: user, product: product) }

        it "does not create the training request" do
          expect { do_request }.not_to change(TrainingRequest, :count)
        end

        it "does not send an email" do
          expect { do_request }.not_to change(ActionMailer::Base.deliveries, :count)
        end
      end
    end
  end
end

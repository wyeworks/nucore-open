# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductUserCreator do
  def create_product_user
    ProductUserCreator.create(user:, product:, approver:)
  end

  let(:user) { create(:user) }
  let(:product) { create(:instrument_requiring_approval) }
  let(:approver) { create(:user, :administrator) }

  describe ".create" do
    let(:product_user) { create_product_user }

    it "creates a ProductUser" do
      expect { create_product_user }.to change(ProductUser, :count).by(1)
    end

    context "when there is a pending training request" do
      let!(:training_request) do
        create(:training_request, user:, product:)
      end

      it "sets the requested_at time" do
        training_request_created_at = training_request.reload.created_at
        expect(product_user.requested_at).to eq(training_request_created_at)
      end

      it "destroys the training request" do
        expect { create_product_user }.to change(TrainingRequest, :count).by(-1)
      end
    end

    context "when there are no pending training requests" do
      it "does not set the requested_at time" do
        expect(product_user.requested_at).to be_blank
      end

      it "does not destroy training requests" do
        expect { create_product_user }.not_to change(TrainingRequest, :count)
      end
    end

    describe "when the user is already approved" do
      before { ProductUser.create!(user:, product:, approved_by: 0) }
      let(:duplicate_product_user) { create_product_user }

      it "does not save" do
        expect(duplicate_product_user).to be_new_record
      end

      it "has an error message" do
        expect(duplicate_product_user.errors).to be_present
      end
    end

    describe "when there is an error on the training request destruction" do
      it "does not save the product_user" do
        expect(ProductUserCreator).to receive(:manage_training_request).and_raise(ActiveRecord::Rollback)
        pu = create_product_user
        expect(pu).not_to be_persisted
      end
    end
  end
end

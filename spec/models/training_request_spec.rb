# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrainingRequest do
  let(:user) { create(:user) }

  describe "#new" do
    subject { build(:training_request, user:, product:) }

    context "when the product has restricted access" do
      let(:product) { create(:instrument_requiring_approval) }

      context "when the user is already on the list" do
        let!(:previous_training_request) do
          create(:training_request, user:, product:)
        end

        it "does not add the user to the list" do
          expect { subject.save }.not_to change(TrainingRequest, :count)
        end

        context "when the user has been removed from the list" do
          before { previous_training_request.destroy }

          it "adds the user to the list" do
            expect { subject.save }.to change(TrainingRequest, :count).by(1)
          end
        end
      end

      context "when the user is not on the list" do
        it "adds the user to the list" do
          expect { subject.save }.to change(TrainingRequest, :count).by(1)
        end
      end
    end

    context "when the product has no restricted access" do
      let(:product) { create(:setup_instrument) }

      it "does not add the user to the list" do
        expect { subject.save }.not_to change(TrainingRequest, :count)
      end
    end
  end

  describe ".submitted?" do
    let(:product) { create(:instrument_requiring_approval) }

    context "when the user has not submitted a request for access" do
      it "returns false" do
        expect(TrainingRequest.submitted?(user, product)).to be false
      end
    end

    context "when the user has submitted a request for access" do
      before { create(:training_request, user:, product:) }

      it "returns true" do
        expect(TrainingRequest.submitted?(user, product)).to be true
      end
    end
  end
end

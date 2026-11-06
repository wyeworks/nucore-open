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

  describe "note" do
    subject(:training_request) { create(:training_request, user:) }

    it "is valid when blank" do
      expect(training_request).to be_valid
    end

    it "is valid at 1000 characters" do
      training_request.note = "a" * 1000
      expect(training_request).to be_valid
    end

    it "is invalid beyond 1000 characters" do
      training_request.note = "a" * 1001
      expect(training_request).not_to be_valid
      expect(training_request.errors).to be_added(:note, :too_long, count: 1000)
    end
  end

  describe "#update_note" do
    subject(:training_request) { create(:training_request, user:) }

    let(:editor) { create(:user) }

    it "saves the note" do
      expect(training_request.update_note("Emailed them", editor)).to be true
      expect(training_request.reload.note).to eq("Emailed them")
    end

    it "stamps who wrote it and when" do
      stamped_at = 1.hour.ago.change(usec: 0)

      travel_to_and_return(stamped_at) do
        training_request.update_note("Emailed them", editor)
      end

      expect(training_request.reload).to have_attributes(
        note_updated_by: editor,
        note_updated_at: stamped_at,
      )
    end

    context "when the note is saved again unchanged" do
      let(:other_editor) { create(:user) }
      let(:original_time) { 2.days.ago.change(usec: 0) }

      before do
        travel_to_and_return(original_time) { training_request.update_note("Emailed them", editor) }
      end

      it "leaves the byline alone" do
        training_request.update_note("Emailed them", other_editor)

        expect(training_request.reload).to have_attributes(
          note_updated_by: editor,
          note_updated_at: original_time,
        )
      end

      it "restamps once the text actually changes" do
        training_request.update_note("Called them instead", other_editor)

        expect(training_request.reload.note_updated_by).to eq(other_editor)
        expect(training_request.reload.note_updated_at).to be > original_time
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

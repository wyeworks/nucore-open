# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::SubmissionsController do
  let(:facility) { FactoryBot.create(:facility, sanger_sequencing_enabled: true) }
  let(:submission) { FactoryBot.create(:sanger_sequencing_submission) }
  let(:user) { FactoryBot.create(:user) }

  before do
    allow_any_instance_of(SangerSequencing::Submission).to receive(:facility).and_return(facility)
    allow_any_instance_of(SangerSequencing::Submission).to receive(:purchased?).and_return(false)
    allow_any_instance_of(SangerSequencing::Submission).to receive(:user).and_return(user)
  end

  describe "#edit" do
    describe "as the purchaser" do
      before { sign_in user }
      it "has access" do
        get :edit, params: { id: submission.id }
        expect(response).to be_successful
      end
    end

    describe "as someone else" do
      let(:other_user) { FactoryBot.create(:user) }
      before { sign_in other_user }
      it "does not have access" do
        get :edit, params: { id: submission.id }
        expect(response.code).to eq("403")
      end
    end

    describe "as a global admin" do
      let(:admin) { FactoryBot.create(:user, :administrator) }
      before { sign_in admin }
      it "does not have access" do
        get :edit, params: { id: submission.id }
        expect(response.code).to eq("403")
      end
    end
  end
end

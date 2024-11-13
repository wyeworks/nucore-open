# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::SpeedTypeSynchronizer, type: :service do
  let(:updater) { described_class.new(speed_type_acct) }
  let(:far_future_date) { 100.years.from_now }
  let(:past_date) { 4.weeks.ago }
  let(:project_id) { nil }
  let(:now) { Time.current }

  describe "#run!" do
    context "when speed_type_account expires_at and api date_removed don't match" do
      let!(:speed_type_acct) { create(:speed_type_account, :with_account_owner, expires_at: past_date) }
      let!(:api_speed_type) { create(:api_speed_type, :expired, speed_type: speed_type_acct.account_number, project_id: project_id, date_removed: now) }

      it "updates expires_at to match the api_speed_type" do
        expect { described_class.run! }.to(change { speed_type_acct.reload.expires_at }.to(api_speed_type.date_removed))
      end
    end
  end

  describe "#run" do
    context "when speed_type_account expires_at and api date_removed don't match" do
      let!(:speed_type_acct) { create(:speed_type_account, :with_account_owner, expires_at: past_date) }
      let!(:api_speed_type) { create(:api_speed_type, :expired, speed_type: speed_type_acct.account_number, project_id: project_id,  date_removed: now) }

      it "updates expires_at to match the api_speed_type" do
        expect { updater.run }.to(change { speed_type_acct.expires_at }.to(api_speed_type.date_removed))
      end
    end

    context "when api date_removed is nil" do
      let!(:speed_type_acct) { create(:speed_type_account, :with_account_owner, expires_at: past_date) }
      let!(:api_speed_type) { create(:api_speed_type, speed_type: speed_type_acct.account_number, project_id: project_id, date_removed: nil) }

      it "updates expires_at to match the api_speed_type" do
        expect { updater.run }.to(change { speed_type_acct.expires_at })
        expect(speed_type_acct.expires_at).to be > far_future_date
      end
    end

    context "when speed_type_account expires_at is far in the future (aka nil)" do
      let!(:speed_type_acct) { create(:speed_type_account, :with_account_owner, expires_at: far_future_date) }
      let!(:api_speed_type) { create(:api_speed_type, :expired, speed_type: speed_type_acct.account_number, project_id: project_id, date_removed: now) }

      it "updates expires_at to match the api_speed_type" do
        expect { updater.run }.to(change { speed_type_acct.expires_at }.to(now))
      end
    end

    context "when speed_type_account expires_at is far in the future (aka nil) and api date_removed is nil" do
      let!(:speed_type_acct) { create(:speed_type_account, :with_account_owner, expires_at: far_future_date) }
      let!(:api_speed_type) { create(:api_speed_type, speed_type: speed_type_acct.account_number, project_id: project_id, date_removed: nil) }

      it "doesn't change the dates" do
        expect { updater.run }.not_to(change { speed_type_acct.expires_at })
      end
    end

    context "when expiration dates are the same" do
      let!(:speed_type_acct) { create(:speed_type_account, :with_account_owner, expires_at: past_date) }
      let!(:api_speed_type) { create(:api_speed_type, :expired, speed_type: speed_type_acct.account_number, project_id: project_id, date_removed: past_date) }

      it "doesn't change the dates" do
        expect { updater.run }.not_to(change { speed_type_acct.expires_at })
      end
    end

    context "when the project_id is not nil" do
      let(:project_id) { "S17110000000118" }
      let(:project_end_date) { past_date + 2.weeks }
      let(:date_removed) { past_date + 3.weeks }
      let(:expires_at) { UmassCorum::SpeedTypeAccount.default_nil_exp_date }

      let!(:speed_type_acct) { create(:speed_type_account, :with_account_owner, expires_at:) }

      context "when the project end date and expiration date are not the same" do
        let(:date_removed) { nil }
        let!(:api_speed_type) { create(:api_speed_type, :expired, speed_type: speed_type_acct.account_number, project_id:, project_end_date:, date_removed:) }

        it "updates expires_at to match the api_speed_type's project_end_date" do
          # binding.pry
          expect { updater.run }.to(change { speed_type_acct.expires_at }.to(project_end_date))
        end
      end

      context "when the project_end_date is nil" do
        let(:project_end_date) { nil }
        let!(:api_speed_type) { create(:api_speed_type, :expired, speed_type: speed_type_acct.account_number, project_id:, project_end_date:, date_removed:) }

        it "updates expires_at to match the api_speed_type's date_removed" do
          expect { updater.run }.to(change { speed_type_acct.expires_at }.to(date_removed))
        end
      end
    end

    context "with no matching api_speed_type" do
      let!(:speed_type_acct) { create(:speed_type_account, :with_account_owner, expires_at: past_date) }
      let(:error) { UmassCorum::SpeedTypeSynchronizationError.new(speed_type_acct.id) }

      it "logs an error and keeps going" do
        expect(ActiveSupport::Notifications).to receive(:instrument).with("background_error", exception: error)
        expect { updater.run }.not_to(change { speed_type_acct.expires_at })
      end
    end
  end
end

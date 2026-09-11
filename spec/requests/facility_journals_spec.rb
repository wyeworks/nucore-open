# frozen_string_literal: true

require "rails_helper"

RSpec.describe "facilities journals" do
  describe "search" do
    let(:facility) { create(:setup_facility) }

    before { login_as create(:user, :administrator) }

    it "includes checkbox to filter suspended accounts" do
      get new_facility_journal_path(facility)

      expect(page).to have_field("search[suspended_accounts]", type: :checkbox)
    end
  end

  describe "create" do
    let(:facility) { create(:setup_facility) }
    let(:product) { create(:setup_item, facility:) }
    let(:order) { create(:complete_order, product:) }
    let(:params) do
      {
        journal_date: Date.today,
        order_detail_ids: order.order_details.pluck(:id),
      }
    end
    let(:action) do
      lambda do
        post facility_journals_path(facility), params:
      end
    end

    before do
      order.order_details.update_all(reviewed_at: 1.day.ago)
    end

    before { login_as create(:user, :administrator) }

    context "on success" do
      it "redirects to index" do
        action.call

        expect(response).to have_http_status(:found)
        expect(response.location).to eq(facility_journals_url(facility))
      end

      it "creates a pending journal" do
        expect { action.call }.to(
          change { facility.journals.count }.by(1)
        )
      end
    end

    context "on error" do
      context "when duplicate pending" do
        before { create(:journal, facility:, is_successful: nil) }

        it "redirects to new" do
          action.call

          expect(response).to have_http_status(:found)
          expect(response.location).to eq(new_facility_journal_url(facility))
        end

        it "renders correct error" do
          action.call
          get response.location

          expect(page).to have_text(I18n.t("controllers.facility_journals.create.duplicate"))
        end
      end
    end
  end
end

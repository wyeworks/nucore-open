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

    context "on error", :use_test_account, :test_account_internal do
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

      context "when creation fail half way on journal rows creation" do
        let(:other_product) { create(:setup_item, facility:) }
        let(:account) do
          create(:test_account, :with_account_owner, created_by: 1)
        end
        let(:other_account) do
          create(:test_account, :with_account_owner, created_by: 1)
        end
        let(:order) { create(:complete_order, product: product, account:) }
        let(:order2) do
          create(:complete_order, product: other_product, account: other_account)
        end
        let(:order_details) do
          OrderDetail.where(order_id: [order.id, order2.id]).tap do |order_details|
            order_details.update_all(reviewed_at: 1.day.ago)
          end
        end
        let(:params) do
          {
            journal_date: Date.today,
            order_detail_ids: order_details.pluck(:id),
          }
        end

        before do
          # Force validation error on transactions from order 2
          other_account.update(expires_at: 1.year.ago)
        end

        it "does not create a journal" do
          expect { action.call }.not_to(
            change { Journal.count }
          )
        end

        it "includes creation error" do
          action.call

          expect(response).to have_http_status(:found)
          expect(response.location).to eq(new_facility_journal_url(facility))

          get response.location

          expect(page).to have_text("account expired")
        end
      end
    end
  end
end

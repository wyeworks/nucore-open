# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkEmail::BulkEmailController do
  render_views

  let(:facility) { facility_account.facility }
  let(:facility_account) { FactoryBot.create(:facility_account) }
  let!(:instrument) { FactoryBot.create(:instrument, facility_account: facility_account) }
  let!(:item) { FactoryBot.create(:item, facility_account: facility_account) }
  let(:params) { { facility_id: facility.url_name } }
  let!(:restricted_item) { FactoryBot.create(:item, facility_account: facility_account, requires_approval: true) }
  let!(:service) { FactoryBot.create(:service, facility_account: facility_account) }

  describe "POST #search" do
    context "when not logged in" do
      before { post "search", params: params }
      it { is_expected.to redirect_to(new_user_session_url) }
    end

    context "when logged in" do
      let(:params) { super().merge(bulk_email: { user_types: user_types }) }
      let!(:hidden_product) { nil }
      let(:user_types) { [] }
      let!(:order) { FactoryBot.create(:purchased_order, product: service) }
      let(:customer) { order.user }
      let!(:authorized_user) { FactoryBot.create(:user) }
      let!(:product_user) { FactoryBot.create(:product_user, user: authorized_user, product_id: restricted_item.id) if restricted_item }

      before do
        sign_in user
        post "search", params: params
      end

      shared_examples_for "it can search for recipients" do
        context "when at least one user_type is set" do
          let(:user_types) { %i(customers) }
          it { expect(assigns[:users]).not_to be_nil }
        end

        context "when no user_types are set" do
          let(:user_types) { [] }
          it { expect(assigns[:users]).to be_blank }
        end

        context "parameter settings" do
          let(:user_types) { %i(customers) }

          it "sets products, in order" do
            expect(assigns[:search_options][:products])
              .to eq([item, service, instrument, restricted_item].sort)
          end

          it "sets user_types, in order", feature_setting: { training_requests: true } do
            expect(assigns[:user_types].keys)
              .to eq(%i(customers authorized_users training_requested account_owners problem_reservation))
          end

          context "when where are no restricted instruments" do
            let!(:restricted_item) { nil }

            it "does not include authorized_users as a user_type" do
              expect(assigns[:user_types]).not_to include(:authorized_users)
            end
          end

          describe "finding users" do
            context "searching for customers" do
              let(:params) do
                { facility_id: facility.url_name,
                  commit: "Search",
                  bulk_email: {
                    user_types: %w[customers],
                  } }
              end

              it "finds users" do
                expect(assigns[:users]).to eq([customer])
              end
            end

            context "searching for authorized users" do
              let(:params) do
                { facility_id: facility.url_name,
                  commit: "Search",
                  bulk_email: {
                    user_types: %w[authorized_users],
                  } }
              end

              it "finds users" do
                expect(assigns[:users]).to eq([authorized_user])
              end
            end
          end
        end

        context "when there is a hidden product" do
          let(:user_types) { %i(customers) }
          let!(:hidden_product) do
            FactoryBot.create(:item, :hidden, facility_account: facility_account)
          end

          it { expect(assigns[:search_options][:products]).to include(hidden_product) }
        end

        context "when there is an archived product" do
          let(:user_types) { %i(customers) }

          let!(:archived_product) do
            FactoryBot.create(:item, :archived, facility_account: facility_account)
          end

          it { expect(assigns[:search_options][:products]).not_to include(archived_product) }
        end
      end

      context "as an unprivileged user" do
        let(:user) { FactoryBot.create(:user) }
        it { is_expected.to render_template("errors/forbidden") }
      end

      context "when logged in as facility staff" do
        let(:user) { FactoryBot.create(:user, :staff, facility: facility) }
        it { is_expected.to render_template("errors/forbidden") }
      end

      context "when logged in as senior facility staff" do
        let(:user) { FactoryBot.create(:user, :senior_staff, facility: facility) }
        it_behaves_like "it can search for recipients"
      end

      context "when logged in as a global billing administrator" do
        let(:user) { FactoryBot.create(:user, :global_billing_administrator) }

        context "in a cross-facility context" do
          let(:facility) { Facility.cross_facility }
          it { is_expected.to render_template("errors/forbidden") }
        end
      end

      context "when logged in as an admin in the cross facility context" do
        let(:user) { FactoryBot.create(:user, :administrator) }
        let(:facility) { Facility.cross_facility }
        let(:params) { super().merge(facility_id: "all") }
        it_behaves_like "it can search for recipients"
      end
    end
  end

  describe "POST #create" do
    let(:params) do
      super().merge(format: :csv, recipient_ids: recipients.map(&:id))
    end

    let(:recipients) { FactoryBot.create_list(:user, 3) }
    let(:expected_csv_content) { csv_header + "\n" + expected_csv_body + "\n" }
    let(:csv_header) { "Name,Username,Email" }
    let(:expected_csv_body) do
      recipients.map do |user|
        [user.full_name, user.username, user.email].join(",")
      end.join("\n")
    end
    let(:user) { FactoryBot.create(:user, :senior_staff, facility: facility) }

    before do
      sign_in user
      post "create", params: params
    end

    it "generates the expected CSV" do
      expect(response.headers["Content-Disposition"])
        .to eq('attachment; filename="bulk_email_recipients.csv"')
      expect(response.body).to eq(expected_csv_content)
    end
  end

  describe "POST #deliver" do
    let(:recipients) { FactoryBot.create_list(:user, 3) }
    let(:custom_message) { "Custom message" }
    let(:user) { FactoryBot.create(:user, :senior_staff, facility: facility) }

    let(:params) do
      super().merge(bulk_email_delivery_form: {
                      custom_subject: custom_subject,
                      custom_message: custom_message,
                      recipient_ids: recipients.map(&:id),
                      search_criteria: {
                        start_date: "12/31/1999",
                        end_date: "1/1/2016",
                        bulk_email: { user_types: ["customers"], products: [1] },
                      }.to_json,
                    })
    end

    before do
      sign_in user
      post "deliver", params: params
    end

    context "when the form is valid" do
      let(:custom_subject) { "Custom subject" }
      let(:default_return_path) { facility_bulk_email_path }

      context "when no return_path param specified" do
        it "submits successfully" do
          is_expected.to redirect_to(default_return_path)
          expect(flash[:notice]).to include("3 email messages queued")
        end
      end

      context "when specifying a return_path param" do
        let(:params) { super().merge(return_path: return_path) }

        context "that is routable" do
          let(:return_path) { facility_instruments_path(facility) }
          it { is_expected.to redirect_to(return_path) }
        end

        context "that is a full URL" do
          let(:return_path) { "http://example.net/" }
          it { is_expected.to redirect_to(default_return_path) }
        end

        context "that is not routable" do
          let(:return_path) { "a bad return path value" }
          it { is_expected.to redirect_to(default_return_path) }
        end
      end
    end

    context "when the form is invalid" do
      let(:custom_subject) { "" }

      it "redisplays the form with errors" do
        is_expected.to render_template(:create)
        expect(assigns[:delivery_form].errors[:custom_subject])
          .to include("can't be blank")
      end
    end
  end
end

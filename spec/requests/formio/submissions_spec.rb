# frozen_string_literal: true

require "rails_helper"

RSpec.describe "formio::submissions", type: :request do
  let(:product) { create(:setup_service) }
  let(:order) { create(:setup_order, product:) }
  let(:order_detail) { order.order_details.last }
  let(:user) { create(:user) }
  let(:params) do
    {
      receiver_id: order_detail.id,
      formio_url: "https://form.io/some/formio/url",
      success_url: "https://nucore.test/some/success/url",
      referer: "https://nucore.test/",
    }
  end

  before { login_as user }

  describe "#new" do
    it "renders the form correctly" do
      get(new_formio_submission_path, params:)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "#show" do
    it "renders the form correctly" do
      get(formio_submission_path, params:)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "#edit" do
    it "renders the form correctly" do
      get(edit_formio_submission_path, params:)

      expect(response).to have_http_status(:ok)
    end
  end
end

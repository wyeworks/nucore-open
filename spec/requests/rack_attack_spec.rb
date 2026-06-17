# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rack::Attack", type: :request do
  let(:login_limit) { Settings.rack_attack.login_limit }
  let(:credentials) { { user: { email: "nobody@example.com", password: "wrong" } } }

  around do |example|
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true

    example.run

    Rack::Attack.enabled = false
    Rack::Attack.cache.store = original_store
  end

  describe "login throttling" do
    it "allows requests up to the limit" do
      login_limit.times { post "/users/sign_in", params: credentials }

      expect(response).not_to have_http_status(:too_many_requests)
    end

    it "returns 429 once the limit is exceeded" do
      (login_limit + 1).times { post "/users/sign_in", params: credentials }

      expect(response).to have_http_status(:too_many_requests)
    end

    it "renders the branded error page with a Retry-After header" do
      (login_limit + 1).times { post "/users/sign_in", params: credentials }

      expect(response.content_type).to include("text/html")
      expect(response.headers["Retry-After"]).to eq(Settings.rack_attack.login_period.to_s)
      expect(response.body).to include("Too many requests")
    end
  end

  context "when disabled" do
    around do |example|
      Rack::Attack.enabled = false
      example.run
    end

    it "never throttles" do
      (login_limit + 5).times { post "/users/sign_in", params: credentials }

      expect(response).not_to have_http_status(:too_many_requests)
    end
  end
end

require "rack/mock"
require "rails_helper"

RSpec.describe Nucore::ExceptionsApp do
  let(:app) { ->(env) { [200, env, "OK"] } }
  let(:middleware) { described_class.new(app) }

  context "when HTTP_ACCEPT header is valid" do
    it "does not alter the headers" do
      env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "text/html,application/json")
      status, headers, _body = middleware.call(env)

      expect(env["HTTP_ACCEPT"]).to eq("text/html,application/json")
      expect(status).to eq(200)
    end
  end

  context "when HTTP_ACCEPT header is invalid" do
    it "sets CONTENT_TYPE to text/html" do
      env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "../../../../../etc/passwd{{")
      status, headers, _body = middleware.call(env)

      expect(env["CONTENT_TYPE"]).to eq("text/html")
      expect(status).to eq(200)
    end
  end

  context "when HTTP_ACCEPT header is missing" do
    it "does not alter the headers" do
      env = Rack::MockRequest.env_for("/")
      status, headers, _body = middleware.call(env)

      expect(env["CONTENT_TYPE"]).to be_nil
      expect(status).to eq(200)
    end
  end
end

require "rack/mock"
require "rails_helper"

RSpec.describe SanitizeHeadersMiddleware do
  let(:app) { ->(env) { [200, env, "OK"] } }
  let(:middleware) { described_class.new(app) }

  it "sanitizes invalid HTTP_ACCEPT headers" do
    env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "../../../../../etc/passwd{{")
    status, headers, _body = middleware.call(env)
    expect(env["HTTP_ACCEPT"]).to eq("*/*")
    expect(status).to eq(200)
  end

  it "allows valid HTTP_ACCEPT headers" do
    env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "text/html,application/json")
    status, headers, _body = middleware.call(env)
    expect(env["HTTP_ACCEPT"]).to eq("text/html,application/json")
    expect(status).to eq(200)
  end
end

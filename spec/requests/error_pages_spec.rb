# frozen_string_literal: true

require "rails_helper"

RSpec.describe "error pages", :disable_requests_local do
  it "handles routing error" do
    get "/some/path"

    expect(response.body).to include("Sorry, we could not find the page you are looking for.")
  end

  it "handles mime type errors" do
    get facilities_path, headers: { "ACCEPT" => "something that's not valid" }

    expect(response).to have_http_status(:not_acceptable)
  end
end

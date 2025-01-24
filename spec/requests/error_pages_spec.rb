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

  it "handles acting as error" do
    allow_any_instance_of(FacilitiesController).to receive(:index).and_raise(
      NUCore::NotPermittedWhileActingAs
    )

    get facilities_path

    expect(response).to have_http_status(:forbidden)
    expect(response.body).to include(
      "This function is unavailable while you are acting as another user"
    )
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "login disabled" do
  let(:password) { "Example1!" }
  let(:normal_user) { create(:user, password:) }
  let(:administrator_user) { create(:user, :administrator, password:) }

  context "when login disabled" do
    before do
      allow(Settings.login).to receive(:disabled).and_return(true)
    end

    it "shows banner on the top" do
      get root_path

      expect(page).not_to have_content(Settings.login.disabled_banner)
    end

    it "cannot login as normal user" do
      params = { user: { username: normal_user.username, password: } }
      post(new_user_session_path, params:)

      expect(response.location).to eq(new_user_session_url)
      get response.location

      expect(page).to have_content(Settings.login.disabled_error)
    end

    it "can login as global admin" do
      params = { user: { username: administrator_user.username, password: } }
      post(new_user_session_path, params:)

      expect(response.location).to eq(root_url)
      expect(page).not_to have_content(Settings.login.disabled_banner)
    end
  end
end

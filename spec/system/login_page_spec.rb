# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Login page", :aggregate_failures do
  # Forks register their own partials on these hooks. Clear them for each example
  # and put them back afterwards so this spec behaves the same in every fork.
  def login_hooks
    [
      ["devise.sessions.new", "login_page"],
      ["devise.sessions.new", "before_login_form"],
      ["devise.sessions.new", "login_form"],
      ["devise.sessions.new", "login_screen_announcement"],
      ["devise.sessions.split_login", "internal_login"],
      ["devise.sessions.split_login", "external_login_links"],
    ]
  end

  def clear_login_hooks
    login_hooks.each do |view, placement|
      ViewHook.find(view, placement).dup.each { |partial| ViewHook.remove_hook(view, placement, partial) }
    end
  end

  around do |example|
    saved_hooks = login_hooks.index_with { |view, placement| ViewHook.find(view, placement).dup }
    clear_login_hooks
    example.run
  ensure
    clear_login_hooks
    saved_hooks.each do |(view, placement), partials|
      partials.each { |partial| ViewHook.add_hook(view, placement, partial) }
    end
  end

  let(:user) { create(:user, :external) }

  describe "default layout" do
    it "shows the single login form and logs the user in" do
      visit new_user_session_path

      expect(page).not_to have_css(".split-login")

      fill_in "Username", with: user.username
      fill_in "Password", with: "P@ssw0rd!!"
      click_button "Login"

      expect(page).to have_content("Logout")
    end
  end

  describe "split layout" do
    before do
      ViewHook.add_hook("devise.sessions.new", "login_page", "devise/sessions/split_login")
    end

    it "shows the internal and external panels and logs the user in" do
      visit new_user_session_path

      expect(page).to have_content("Choose the option that matches your affiliation.")
      expect(page).to have_css(".split-login__panel--internal")
      within(".split-login__panel--external") do
        expect(page).to have_content("External users")

        fill_in "Username", with: user.username
        fill_in "Password", with: "P@ssw0rd!!"
        # The submit label is overridable per fork, so don't rely on its text
        find("[type=submit]").click
      end

      expect(page).to have_content("Logout")
    end
  end
end

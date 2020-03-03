# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Passwords", :aggregate_failures, feature_setting: { password_update: true, reload_routes: true } do
  let(:external_user) { FactoryBot.create(:user, :external, password: "originalpassword") }
  let(:internal_user) { FactoryBot.create(:user, password: "originalpassword") }

  describe "Changing" do
    describe "as an external user" do
      before do
        login_as external_user
        visit root_path
        click_link "Change Password"
      end

      describe "correct password" do
        before do
          fill_in "Current password", with: "originalpassword"
          fill_in "user[password]", with: "newpassword"
          fill_in "user[password_confirmation]", with: "newpassword"
          click_button "Change Password"
        end

        it "changes the password" do
          expect(page).to have_content "Your password has been updated"
          expect(external_user.reload).to be_valid_password("newpassword")
        end
      end

      describe "incorrect password" do
        before do
          fill_in "Current password", with: "random"
          fill_in "user[password]", with: "newpassword"
          fill_in "user[password_confirmation]", with: "newpassword"
          click_button "Change Password"
        end

        it "has an error" do
          expect(page).to have_content "Current password is incorrect"
        end
      end
    end

    describe "as a user who cannot update their password" do
      before do
        login_as internal_user
        visit root_path
      end

      it "does not have a change password link" do
        expect(page).not_to have_link "Change Password"
      end

      it "receives an error when trying to access the edit password page" do
        visit edit_current_password_path
        expect(page).to have_content "You cannot change this user's password"
      end
    end
  end

  describe "Resetting" do
    before do
      clear_emails
      visit new_user_session_path
      click_link "Forgot password?"
    end

    describe "as the external user" do

      before do
        fill_in "Email", with: external_user.email
        click_button "Submit"
      end

      it "gets an email and can reset the password" do
        open_email(external_user.email)
        current_email.click_link "Change my password"
        fill_in "New password", with: "newpassword"
        fill_in "Confirm your new password", with: "newpassword"
        click_button "Change my password"

        expect(page).to have_content "Your password has been changed successfully"
        expect(external_user.reload).to be_valid_password("newpassword")
        expect(page).to have_content external_user.email
      end
    end

    describe "as an internal user" do
      before do
        fill_in "Email", with: internal_user.email
        click_button "Submit"
      end

      it "cannot reset" do
        expect(page).to have_content "You cannot change this user's password"
      end
    end
  end
end

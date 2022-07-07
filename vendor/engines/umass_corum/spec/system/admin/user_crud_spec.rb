# frozen_string_literal: true

require "rails_helper"

RSpec.describe do
  let(:facility) { create(:facility) }
  let(:admin) { create(:user, :administrator) }

  before { login_as admin }

  describe "CREATE" do
    describe "internal user creation" do
      it "can successfully create a user" do
        visit new_facility_user_path(facility)
        fill_in "First name", with: "Testing"
        fill_in "Last name", with: "Testerson"
        fill_in "Email", with: "email@example.org"
        fill_in "NetID", with: "ttesterson"

        click_button "Create"

        expect(page).to have_content("You just created a new user, Testing Testerson (ttesterson)")

        expect(ActionMailer::Base.deliveries.last.body.encoded).to include("A CORUM login account has been created for you")
          .and include("use your NetID and password")

        expect(User.find_by!(username: "ttesterson")).to have_attributes(
          username: "ttesterson",
          email: "email@example.org",
          authenticated_locally?: false,
          encrypted_password: be_blank,
        )
      end

      describe "failure cases" do
        describe "email already exists" do
          let!(:existing) { create(:user, email: "existing@example.org") }

          it "cannot create" do
            visit new_facility_user_path(facility)
            fill_in "Email", with: "existing@example.org"

            click_button "Create"
            expect(page).to have_content("Email\nhas already been taken")
          end
        end

        describe "username already exists" do
          let!(:existing) { create(:user, username: "abc123") }

          it "cannot create" do
            visit new_facility_user_path(facility)
            fill_in "NetID", with: "abc123"

            click_button "Create"
            expect(page).to have_content("NetID\nhas already been taken")
          end
        end
      end
    end

    describe "external user creation" do
      it "can successfully create a user" do
        visit new_facility_user_path(facility)
        fill_in "First name", with: "Testing"
        fill_in "Last name", with: "Testerson"
        fill_in "Email", with: "email@example.org"
        check "This user does not have a NetID"

        click_button "Create"

        expect(page).to have_content("You just created a new user, Testing Testerson (email@example.org)")

        expect(ActionMailer::Base.deliveries.last.body.encoded).to include("A CORUM login account has been created for you")
          .and include("using your username and password")

        expect(User.find_by!(username: "email@example.org")).to have_attributes(
          username: "email@example.org",
          email: "email@example.org",
          authenticated_locally?: true,
          encrypted_password: be_present,
        )
      end

      describe "failure" do
        describe "email already exists" do
          let!(:existing) { create(:user, email: "email@example.org") }

          it "cannot create" do
            visit new_facility_user_path(facility)
            fill_in "Email", with: "email@example.org"

            click_button "Create"
            expect(page).to have_content("Email\nhas already been taken")
          end
        end
      end
    end
  end

  describe "EDIT" do
    describe "Internal user" do
      let!(:user) { create(:user, username: "abc123", email: "abc123@umass.edu") }

      it "can update their username" do
        visit edit_facility_user_path(facility, user)

        fill_in "Username/NetID", with: "new321"
        click_button "Update"

        expect(user.reload).to have_attributes(
          username: "new321",
          email: "abc123@umass.edu",
        )
      end

      it "can update their email" do
        visit edit_facility_user_path(facility, user)

        fill_in "Email", with: "new321@umass.edu"
        click_button "Update"

        expect(user.reload).to have_attributes(
          username: "abc123",
          email: "new321@umass.edu",
        )
      end
    end

    describe "external user" do
      let!(:user) { create(:user, :external) }

      it "cannot change the username" do
        visit edit_facility_user_path(facility, user)
        expect(page).to have_field("Username/NetID", readonly: true)
      end

      it "can update the email, which also updates the username", :js do
        visit edit_facility_user_path(facility, user)

        fill_in "Email", with: "new123@umass.edu"
        click_button "Update"

        expect(user.reload).to have_attributes(
          email: "new123@umass.edu",
          username: "new123@umass.edu",
        )
      end
    end
  end
end

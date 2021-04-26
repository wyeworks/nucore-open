# frozen_string_literal: true

require "rails_helper"

RSpec.describe Devise::SessionsController do
  before { @request.env["devise.mapping"] = Devise.mappings[:user] }

  describe "#create, aka logging in" do
    describe "a user with the password in the database" do
      let(:user) { FactoryBot.create(:user, password: "IamAnud0mU$3r", password_confirmation: "IamAnud0mU$3r") }

      specify "can log in" do
        post :create, params: { user: { username: user.username, password: "IamAnud0mU$3r" } }
        expect(controller.current_user).to eq(user)
      end
    end

    describe "a suspended user" do
      let(:user) { create(:user, :suspended, password: "IamAnud0mU$3r", password_confirmation: "IamAnud0mU$3r") }

      specify "can not log in" do
        post :create, params: { user: { username: user.username, password: "IamAnud0mU$3r" } }
        expect { controller.current_user }.to throw_symbol(:warden)
      end
    end
  end
end

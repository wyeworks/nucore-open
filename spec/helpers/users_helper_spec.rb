# frozen_string_literal: true

require "rails_helper"
require "text_helpers/contexts"

RSpec.describe UsersHelper, controller: true do
  let(:facility) { FactoryBot.create(:facility) }
  let(:external_user) { FactoryBot.create(:user, :external) }
  let(:internal_user) { FactoryBot.create(:user) }

  initial_support_email = Settings.support_email

  after(:all) do
    Settings.support_email = initial_support_email
  end

  describe "creation_success_flash_text" do
    context "with support email" do
      before(:all) do
        Settings.support_email = "help@example.com"
      end

      it "gives text for external user" do
        test_string = "<p>The default Price Group for this user is &ldquo;#{Settings.price_group.name.external}.&rdquo; Please notify #{t('app_name')} support at <a href=\"mailto:help@example.com\">help@example.com</a> if this user is entitled to internal&nbsp;rates.</p>"

        expect(creation_success_flash_text(external_user, facility)).to include test_string
      end

      it "gives text for internal user" do
        test_string = "<p>The default Price Group for this user is &ldquo;#{Settings.price_group.name.base}&rdquo; (internal rates). Please notify #{t('app_name')} support at <a href=\"mailto:help@example.com\">help@example.com</a> if this is an external&nbsp;user.</p>"

        expect(creation_success_flash_text(internal_user, facility)).to include test_string
      end
    end

    context "without support email" do
      before(:all) do
        Settings.support_email = nil
      end

      it "gives text for external user" do
        test_string = "<p>The default Price Group for this user is &ldquo;#{Settings.price_group.name.external}.&rdquo; Please notify #{t('app_name')} support if this user is entitled to internal&nbsp;rates.</p>"

        expect(creation_success_flash_text(external_user, facility)).to include test_string
      end

      it "gives text for internal user" do
        test_string = "<p>The default Price Group for this user is &ldquo;#{Settings.price_group.name.base}&rdquo; (internal rates). Please notify #{t('app_name')} support if this is an external&nbsp;user.</p>"

        expect(creation_success_flash_text(internal_user, facility)).to include test_string
      end
    end
  end
end

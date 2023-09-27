# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Translation loading" do
  include TextHelpers::Translation

  describe "I18n.t" do
    it "loads override_locales files" do
      expect(I18n.t("testing.locale_loading")).to start_with("This is here")
    end

    it "gives override_locales precedence over the root files" do
      expect(I18n.t("testing.overriding")).to start_with("This overrides")
    end
  end

  describe "text_helpers" do
    def translation_scope
      ""
    end

    it "loads override_locales files" do
      expect(text("testing.locale_loading")).to start_with("This is here")
    end

    it "gives override_locales precedence over the root files" do
      expect(text("testing.overriding")).to start_with("This overrides")
    end
  end

  describe "load_path" do
    let(:load_path) { Rails.application.config.i18n.load_path }
    let(:override_index) { load_path.find_index("#{Rails.root}/config/override_locales/en.yml") }
    let(:other_index) { load_path.find_index("#{Rails.root}/config/locales/#{other_path}") }

    describe "/en.yml" do
      let(:other_path) { "en.yml" }
      it "happens before override" do
        expect(other_index).to be < override_index
      end
    end

    describe "/views/en.facilities.yml" do
      let(:other_path) { "views/en.facilities.yml" }

      it "happens before override" do
        expect(other_index).to be < override_index
      end
    end

    describe "views/admin" do
      let(:other_path) { "views/admin/en.facilities.yml" }

      it "loads views/admin" do
        expect(other_index).to be_present
      end
    end
  end

end

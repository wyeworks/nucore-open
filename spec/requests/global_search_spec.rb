# frozen_string_literal: true

require "rails_helper"

RSpec.describe "global search" do
  describe "statement search" do
    let(:facility) { create(:facility) }
    let(:statement) { create(:statement, facility:) }
    let(:status_label) do
      Statement.human_attribute_name("status.#{statement.status}")
    end

    before { login_as create(:user, :administrator) }

    it "shows statement correctly" do
      post global_search_path, params: { search: statement.invoice_number }

      expect(page).to have_text(I18n.t("Statements"))
      expect(page).to have_text(statement.invoice_number)
      expect(page).to have_text(status_label)
    end
  end
end

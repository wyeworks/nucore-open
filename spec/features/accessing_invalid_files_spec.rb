require "rails_helper"

RSpec.describe "Accessing invalid formats" do

  it "renders a 404 for a missing page in pdf" do
    visit "/#{I18n.t('facilities_downcase')}/examp.pdf"

    expect(page).to have_content("404")
    expect(page).to have_content("Page Not Found")
  end

  describe "for a page I don't have access to" do
    let(:user) { create(:user) }
    let(:facility) { create(:facility) }

    it "renders a 403 as html" do
      login_as user
      visit "#{I18n.t('facilities_downcase')}/list.pdf"

      expect(page).to have_content("403")
      expect(page).to have_content("Permission Denied")
    end
  end
end

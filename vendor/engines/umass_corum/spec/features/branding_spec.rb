require "rails_helper"

RSpec.describe "Branding" do

  it "should have a logo and copyright information" do
    visit root_path

    expect(page).to have_css("img[src*='.svg'][alt*='UMass']")
    expect(page).to have_content(/\d{4} University of Massachusetts/)
  end

end

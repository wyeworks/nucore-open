# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accessing invalid formats" do
  it "handles invalid utf8 query parameters" do
    visit "/users/sign_in?utf8=%E2%9C%93&user[username]=&user[password]=&commit=Sign+in&authenticity_token=f%e5u6%ac%5d%df%c8S%fc%9c7%b3%ff%26A%c3y%85%a3"

    expect(page.current_path).to eq("/users/sign_in")
    expect(page.text).to include("Login")
  end

  it "renders a 404 for a missing page in pdf" do
    visit "/#{I18n.t('facilities_downcase')}/examp.pdf"
    expect(page).to have_http_status(:not_found)
  end

  describe "for a page I don't have access to" do
    let(:user) { create(:user) }
    let(:facility) { create(:facility) }

    describe "a pdf version of a regular page" do
      it "renders a 403 as html" do
        login_as user

        visit "#{I18n.t('facilities_downcase')}/list.pdf"
        expect(page).to have_http_status(:forbidden)
      end
    end

    describe "a statement pdf" do
      let(:statement) { create(:statement, facility: facility) }

      it "renders a 403 as html" do
        login_as user

        visit "accounts/#{statement.account.id}/statements/#{statement.id}.pdf"
        expect(page).to have_http_status(:forbidden)
      end
    end

    describe "a calendar .ics file" do
      let(:reservation) { create(:purchased_reservation) }

      it "renders a 403 as html" do
        login_as user

        visit "orders/#{reservation.order.id}/order_details/#{reservation.order_detail.id}/reservations/#{reservation.id}.ics"
        expect(page).to have_http_status(:forbidden)
      end
    end
  end
end

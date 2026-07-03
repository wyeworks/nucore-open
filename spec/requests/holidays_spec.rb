# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Holidays" do
  before { login_as create(:user, :administrator) }

  describe "new" do
    it "renders a native date input" do
      get new_holiday_path

      expect(response.body).to include('type="date"')
      expect(response.body).to include('name="holiday[date]"')
    end
  end

  describe "create" do
    it "saves the ISO-formatted date with no server-side parsing" do
      expect do
        post holidays_path, params: { holiday: { date: "2026-12-25" } }
      end.to change(Holiday, :count).by(1)

      expect(Holiday.last.date.to_date).to eq(Date.new(2026, 12, 25))
      expect(response).to redirect_to(holidays_path)
    end
  end

  describe "edit" do
    let(:holiday) { Holiday.create!(date: Date.new(2026, 12, 25)) }

    it "renders the stored date in ISO format" do
      get edit_holiday_path(holiday)

      expect(response.body).to include('value="2026-12-25"')
    end
  end

  describe "update" do
    let(:holiday) { Holiday.create!(date: Date.new(2026, 12, 25)) }

    it "updates from the ISO-formatted date" do
      patch holiday_path(holiday), params: { holiday: { date: "2027-01-01" } }

      expect(holiday.reload.date.to_date).to eq(Date.new(2027, 1, 1))
      expect(response).to redirect_to(holidays_path)
    end
  end
end

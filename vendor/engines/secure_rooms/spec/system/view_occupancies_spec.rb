# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Viewing Occupancies" do
  let(:facility) { create(:setup_facility) }
  let(:secure_room) { create(:secure_room, facility: facility) }
  let(:second_secure_room) { create(:secure_room, facility: facility) }
  let(:facility_staff) { create(:user, :staff, facility: facility) }
  before { login_as facility_staff }

  context "with no Occupancies" do
    it "shows that the room is vacant" do
      visit dashboard_facility_occupancies_path(facility)

      expect(current_path).to eq(dashboard_facility_occupancies_path(facility))
    end
  end

  context "with Occupancies" do
    let!(:active_occupancy) { create(:occupancy, :active, secure_room: secure_room) }
    let!(:orphan_occupancy) { create(:occupancy, :orphan, secure_room: secure_room) }
    let!(:complete_occupancy) { create(:occupancy, :complete, secure_room: secure_room) }
    let!(:second_room_active_occupancy) { create(:occupancy, :active, secure_room: second_secure_room) }

    it "can view only the current Occupancies" do
      visit dashboard_facility_occupancies_path(facility)

      expect(current_path).to eq(dashboard_facility_occupancies_path(facility))
      expect(page).to have_content(active_occupancy.user.full_name)
      expect(page).to have_content(I18n.l(active_occupancy.entry_at, format: :usa))
      expect(page).not_to have_content(orphan_occupancy.user.full_name)
      expect(page).to have_content(complete_occupancy.user.full_name)
      expect(page).to have_content(second_room_active_occupancy.user.full_name)
    end
  end
end

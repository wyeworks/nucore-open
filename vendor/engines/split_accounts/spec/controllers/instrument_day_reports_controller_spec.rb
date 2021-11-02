# frozen_string_literal: true

require "rails_helper"
require_relative "../split_accounts_spec_helper"

RSpec.describe Reports::InstrumentDayReportsController, :enable_split_accounts do
  let(:account) { FactoryBot.create(:split_account, owner: user) }
  let(:instrument) { FactoryBot.create(:setup_instrument, :always_available, facility: facility) }
  let(:facility) { FactoryBot.create(:setup_facility) }
  let!(:reservation) do
    # This is a Thursday
    FactoryBot.create(:completed_reservation, product: instrument,
                                              reserve_start_at: Time.zone.local(2016, 3, 17, 10, 30),
                                              reserve_end_at: Time.zone.local(2016, 3, 17, 12, 30),
                                              actual_start_at: Time.zone.local(2016, 3, 17, 10, 30),
                                              actual_end_at: Time.zone.local(2016, 3, 17, 12, 0)
  )
  end
  let(:user) { reservation.order_detail.account.owner_user }
  let(:admin) { FactoryBot.create(:user, :administrator) }

  before { reservation.order_detail.update!(account: account) }
  before { sign_in admin }

  def do_request(action)
    get :index, params: { report_by: action, facility_id: facility.url_name, date_start: "03/01/2016", date_end: "03/31/2016" }, xhr: true
  end

  describe "reserved_quantity" do
    it "has the correct data" do
      do_request(:reserved_quantity)
      expect(assigns(:rows).first).to eq([instrument.name, "0", "0", "0", "0", "1", "0", "0"])
    end
  end

  describe "reserved_hours" do
    it "has the correct data" do
      do_request(:reserved_hours)
      expect(assigns(:rows).first).to eq([instrument.name, 0, 0, 0, 0, 2, 0, 0])
    end
  end

  describe "actual_quantity" do
    it "has the correct data" do
      do_request(:actual_quantity)
      expect(assigns(:rows).first).to eq([instrument.name, "0", "0", "0", "0", "1", "0", "0"])
    end
  end

  describe "actual_hours" do
    it "has the correct data" do
      do_request(:actual_hours)
      expect(assigns(:rows).first).to eq([instrument.name, 0, 0, 0, 0, 1.5, 0, 0])
    end
  end
end

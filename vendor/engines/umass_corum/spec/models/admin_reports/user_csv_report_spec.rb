# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::AdminReports::UserCsvReport do
  subject(:report) { UmassCorum::AdminReports::UserCsvReport.new }

  describe "#to_csv" do
    context "with no users" do
      it "generates a header", :aggregate_failures do
        lines = report.to_csv.lines
        expect(lines.count).to eq(1)
        expect(lines[0]).to eq("Username,URL,Created,Last Login,Last Order Activity,First Name,Last Name,Safety Certs,Card Number,iClass Number,Global Roles,Email,Phone,Internal Pricing?\n")
      end

      it "sets the filename based on the passed in product name" do
        expect(report.filename).to eq("user_data.csv")
      end
    end

    context "with users" do
      let!(:internal_user) { create(:user, card_number: "9876", i_class_number: "456", phone_number: "123-1234") }
      let!(:external_user) { create(:user, :external) }
      let!(:admin_user) { create(:user, :administrator) }
      let!(:order) { create(:order, :purchased, user: external_user, created_by: external_user.id) }
      let(:cert1) { create(:research_safety_certificate, name: "Lab Safety") }
      let(:cert2) { create(:research_safety_certificate, name: "Intro to Lasers") }

      it "generates a header line and 3 data lines", :aggregate_failures do
        expect(report).to receive(:cert_lookup_for_user).with(User)
                                                        .exactly(3).times
                                                        .and_return({cert1 => true, cert2 => true})

        lines = report.to_csv.lines
        expect(lines.count).to eq(4)
        expect(lines[1]).to eq("#{internal_user.username},/facilities/all/users/#{internal_user.id},#{I18n.l(internal_user.created_at, format: :usa)},\"\",\"\",#{internal_user.first_name},#{internal_user.last_name},Lab Safety;Intro to Lasers,9876,456,\"\",#{internal_user.email},123-1234,Internal\n")
        expect(lines[2]).to eq("#{external_user.username},/facilities/all/users/#{external_user.id},#{I18n.l(external_user.created_at, format: :usa)},\"\",#{I18n.l(order.created_at, format: :usa)},#{external_user.first_name},#{external_user.last_name},Lab Safety;Intro to Lasers,,,\"\",#{external_user.email},,External\n")
        expect(lines[3]).to eq("#{admin_user.username},/facilities/all/users/#{admin_user.id},#{I18n.l(admin_user.created_at, format: :usa)},\"\",\"\",#{admin_user.first_name},#{admin_user.last_name},Lab Safety;Intro to Lasers,,,Administrator,#{admin_user.email},,Internal\n")
      end
    end
  end
end

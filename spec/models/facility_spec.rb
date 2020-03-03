# frozen_string_literal: true

require "rails_helper"

RSpec.describe Facility do
  it "validates", :aggregate_failures do
    is_expected.to validate_presence_of(:name)
    is_expected.to validate_presence_of(:abbreviation)

    is_expected.to allow_value("or-der@test.example.com", "", nil)
      .for(:order_notification_recipient)

    is_expected.not_to allow_value("test.", "*", "@")
      .for(:order_notification_recipient)
  end

  context "when finding problem orders and reservations" do
    subject(:facility) { order.facility }
    let(:order) { create(:purchased_order, product: product) }

    def convert_to_problem_order(order)
      order.order_details.each do |order_detail|
        order_detail.update_attributes(price_policy: nil, state: "complete")
      end
    end

    describe "#problem_plain_order_details" do
      let(:product) { create(:setup_item) }

      context "when there are no problem non-reservations" do
        it { expect(facility.problem_plain_order_details).to be_empty }
      end

      context "when there are problem orders" do
        let(:problem_orders) { order.order_details }

        before { convert_to_problem_order(order) }

        it "returns the problem non-reservation order details" do
          expect(facility.problem_plain_order_details)
            .to match_array(problem_orders)
        end
      end
    end

    describe "#problem_reservation_order_details" do
      let(:product) { create(:setup_instrument) }

      context "when there are no problem reservations" do
        it { expect(facility.problem_reservation_order_details).to be_empty }
      end

      context "when there are problem reservations" do
        let(:problem_reservations) { order.order_details }

        before { convert_to_problem_order(order) }

        it "returns the problem reservation order details" do
          expect(facility.problem_reservation_order_details)
            .to match_array(problem_reservations)
        end
      end
    end
  end

  describe ".training_requests" do
    let(:products) { create_list(:instrument_requiring_approval, 3) }

    before(:each) do
      products.each { |product| create(:training_request, product: product) }
    end

    it "scopes training requests to a facility" do
      products.each do |product|
        expect(product.facility.training_requests.map(&:product))
          .to match_array([product])
      end
    end
  end

  describe ".director_and_admins" do
    let(:facility) { create(:facility) }
    let!(:staff) { create(:user, :staff, facility: facility) }
    let!(:senior_staff) { create(:user, :senior_staff, facility: facility) }
    let!(:admin) { create(:user, :facility_administrator, facility: facility) }
    let!(:director) { create(:user, :facility_director, facility: facility) }

    it "returns only the director and administrators" do
      expect(facility.director_and_admins).to contain_exactly(admin, director)
    end
  end

  context "url_name" do
    it "is only valid with alphanumeric and -_ characters" do
      is_expected.not_to allow_value("abc 123").for(:url_name)
      is_expected.to allow_value("abc-123").for(:url_name)
      is_expected.to allow_value("abc123").for(:url_name)
    end

    it "is not valid with less than 3 or longer than 50 characters" do
      is_expected.not_to allow_value("123456789012345678901234567890123456789012345678901").for(:url_name) # 51 chars
      is_expected.not_to allow_value("12").for(:url_name)
      is_expected.not_to allow_value("").for(:url_name)
      is_expected.not_to allow_value(nil).for(:url_name)
    end

    it "is valid between 3 and 50 characters" do
      is_expected.to allow_value("123").for(:url_name)
      is_expected.to allow_value("12345678901234567890123456789012345678901234567890").for(:url_name) # 50 chars
    end

    it "is unique" do
      @factory1 = FactoryBot.create(:facility)
      @factory2 = FactoryBot.build(:facility, url_name: @factory1.url_name)
      expect(@factory2).not_to be_valid
    end
  end

  describe "#order_statuses" do
    let(:facility) { FactoryBot.create(:facility) }
    let(:other_facility) { FactoryBot.create(:facility) }
    let!(:my_order_statuses) { FactoryBot.create_list(:order_status, 3, facility: facility) }
    let!(:other_order_statuses) { FactoryBot.create_list(:order_status, 3, facility: other_facility) }

    it "returns only statuses belonging to its own facility or no facility" do
      expect(facility.order_statuses)
        .to match_array(my_order_statuses + OrderStatus.where(facility_id: nil))
    end
  end

  describe "#dashboard_enabled/token" do
    it "starts off with no token" do
      facility = described_class.new
      expect(facility.dashboard_token).to be_blank
    end

    it "starts off not enabled" do
      facility = described_class.new
      expect(facility).not_to be_dashboard_enabled
    end

    it "sets the token when you tell it to be enabled" do
      facility = described_class.new(dashboard_enabled: "1")
      expect(facility.dashboard_token).to be_present
    end

    it "enables the dashboard after setting it" do
      facility = described_class.new(dashboard_enabled: "1")
      expect(facility).to be_dashboard_enabled
    end

    it "unsets it if it gets a 'false' string" do
      facility = described_class.new(dashboard_enabled: "0")
      expect(facility).not_to be_dashboard_enabled
    end

    it "does not change the token if you set it to true several times" do
      facility = described_class.new(dashboard_enabled: "1")
      expect { facility.dashboard_enabled = "1" }.not_to change(facility, :dashboard_token)
    end

    it "resets the token if you turn it off and back on" do
      facility = described_class.new(dashboard_enabled: "1")
      expect do
        facility.dashboard_enabled = "0"
        facility.dashboard_enabled = "1"
      end.to change(facility, :dashboard_token)
    end
  end
end

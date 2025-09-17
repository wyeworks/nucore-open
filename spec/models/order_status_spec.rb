# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderStatus do
  let!(:root_statuses) do
    described_class.ordered_root_statuses.map do |root_status_name|
      create(:order_status, name: root_status_name)
    end
  end

  let!(:facility) { create(:facility) }

  describe ".ordered_root_statuses" do
    let(:ordered_root_names) { root_statuses.map(&:name) }

    it "allows adding and removing root order statuses" do
      described_class.ordered_root_statuses << "TEST"
      expect(described_class.ordered_root_statuses).to eq(ordered_root_names + ["TEST"])
      described_class.ordered_root_statuses.pop
      expect(described_class.ordered_root_statuses).to eq(ordered_root_names)
    end
  end

  describe ".new_status" do
    let!(:new_order_status) { create(:order_status, name: "New") }

    it "returns the 'New' order status" do
      expect(described_class.new_status).to eq(new_order_status)
    end
  end

  describe ".root_statuses" do
    it "returns all of the root statuses in order" do
      expect(described_class.root_statuses).to eq root_statuses
    end
  end

  describe ".default_order_status" do
    it "returns the 'New' status" do
      expect(described_class.default_order_status).to eq(described_class.new_status)
    end
  end

  describe ".initial_statuses" do
    let!(:facility_status) do
      create(:order_status, facility: facility, parent: described_class.new_status, name: "Brand New")
    end

    let!(:other_status) do
      create(:order_status, facility: create(:facility), parent: described_class.new_status, name: "Other Brand New")
    end

    context "without product parameter (default behavior)" do
      it "returns all new and in process statuses for the facility" do
        expected_statuses = [
          described_class.new_status,
          facility_status,
          described_class.in_process,
        ]

        expect(described_class.initial_statuses(facility)).to eq(expected_statuses)
      end

      it "returns all new and in process statuses in cross-facility context" do
        expected_statuses = [
          described_class.new_status,
          described_class.in_process,
        ]

        expect(described_class.initial_statuses(nil)).to eq(expected_statuses)
      end
    end

    context "with an Item product" do
      let(:item) { build(:item) }

      context "when item_initial_order_status_complete feature is on", feature_setting: { item_initial_order_status_complete: true } do
        it "returns all new, in process, and complete statuses for the facility" do
          expected_statuses = [
            described_class.new_status,
            facility_status,
            described_class.in_process,
            described_class.complete,
          ]

          expect(described_class.initial_statuses(facility, product: item)).to eq(expected_statuses)
        end

        it "returns all new, in process, and complete statuses in cross-facility context" do
          expected_statuses = [
            described_class.new_status,
            described_class.in_process,
            described_class.complete,
          ]

          expect(described_class.initial_statuses(nil, product: item)).to eq(expected_statuses)
        end
      end

      context "when item_initial_order_status_complete feature is off", feature_setting: { item_initial_order_status_complete: false } do
        it "returns same as default even for Item products" do
          expected_statuses = [
            described_class.new_status,
            facility_status,
            described_class.in_process,
          ]

          expect(described_class.initial_statuses(facility, product: item)).to eq(expected_statuses)
        end
      end
    end

    context "with other product types" do
      let(:service) { build(:service) }
      let(:instrument) { build(:instrument) }

      it "returns same as default for non-item product types" do
        expected_statuses = [
          described_class.new_status,
          facility_status,
          described_class.in_process,
        ]

        expect(described_class.initial_statuses(facility, product: service)).to eq(expected_statuses)
        expect(described_class.initial_statuses(facility, product: instrument)).to eq(expected_statuses)
        expect(described_class.initial_statuses(facility, product: nil)).to eq(expected_statuses)
      end
    end
  end

  describe ".non_protected_statuses" do
    let!(:facility_status) do
      create(:order_status, facility: facility, parent: described_class.canceled, name: "Due to Bad Weather")
    end

    let!(:other_status) do
      create(:order_status, facility: create(:facility), parent: described_class.new_status, name: "Other Brand New")
    end

    it "returns all non-reconciled statuses for the facility" do
      expected_statuses = [
        described_class.new_status,
        described_class.in_process,
        described_class.canceled,
        facility_status,
        described_class.complete,
        described_class.unrecoverable,
      ]

      expect(described_class.non_protected_statuses(facility)).to eq(expected_statuses)
    end

    it "returns all non-reconciled statuses in cross-facility context" do
      expected_statuses = [
        described_class.new_status,
        described_class.in_process,
        described_class.canceled,
        described_class.complete,
        described_class.unrecoverable,
      ]

      expect(described_class.non_protected_statuses(nil)).to eq(expected_statuses)
    end
  end

  describe "#state_name" do
    it "identifies the correct name for a root status" do
      expect(described_class.in_process.state_name).to eq(:inprocess)
      expect(described_class.canceled.state_name).to eq(:canceled)
    end

    it "uses the base status for a facility status" do
      status = create(:order_status, parent: described_class.in_process)
      expect(status.state_name).to eq(:inprocess)
    end
  end

  describe "#self_and_descendants" do
    it "returns the root record and its children" do
      child_status = create(:order_status, parent: described_class.canceled)
      expect(described_class.canceled.self_and_descendants).to eq([
        described_class.canceled,
        child_status,
      ])
    end
  end
end

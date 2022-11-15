# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderStatus do
  let!(:root_statuses) do
    new_status = create(:order_status, name: "New")
    in_process = create(:order_status, name: "In Process")
    canceled = create(:order_status, name: "Canceled")
    complete = create(:order_status, name: "Complete")
    reconciled = create(:order_status, name: "Reconciled")

    {
      new: new_status,
      in_process: in_process,
      canceled: canceled,
      complete: complete,
      reconciled: reconciled,
    }
  end

  let!(:facility) { create(:facility) }

  describe ".ordered_root_statuses" do
    let(:ordered_roots) { root_statuses.values.map(&:name) }

    it "allows adding and removing root order statuses" do
      OrderStatus.ordered_root_statuses << "TEST"
      expect(described_class.ordered_root_statuses).to eq(ordered_roots + ["TEST"])
      OrderStatus.ordered_root_statuses.pop
      expect(described_class.ordered_root_statuses).to eq(ordered_roots)
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
      expect(described_class.root_statuses).to eq root_statuses.values
    end
  end

  describe ".default_order_status" do
    it "returns the 'New' status" do
      expect(described_class.default_order_status).to eq(root_statuses[:new])
    end
  end

  describe ".initial_statuses" do
    let!(:facility_status) do
      create(:order_status, facility: facility, parent: root_statuses[:new], name: "Brand New")
    end

    let!(:other_status) do
      create(:order_status, facility: create(:facility), parent: root_statuses[:new], name: "Other Brand New")
    end

    it "returns all new and in process statuses for the facility" do
      expected_statuses = [
        root_statuses[:new],
        facility_status,
        root_statuses[:in_process],
      ]

      expect(described_class.initial_statuses(facility)).to eq(expected_statuses)
    end

    it "returns all new and in process statuses in cross-facility context" do
      expected_statuses = [
        root_statuses[:new],
        root_statuses[:in_process],
      ]

      expect(described_class.initial_statuses(nil)).to eq(expected_statuses)
    end
  end

  describe ".non_protected_statuses" do
    let!(:facility_status) do
      create(:order_status, facility: facility, parent: root_statuses[:canceled], name: "Due to Bad Weather")
    end

    let!(:other_status) do
      create(:order_status, facility: create(:facility), parent: root_statuses[:new], name: "Other Brand New")
    end

    it "returns all non-reconciled statuses for the facility" do
      expected_statuses = [
        root_statuses[:new],
        root_statuses[:in_process],
        root_statuses[:canceled],
        facility_status,
        root_statuses[:complete],
      ]

      expect(described_class.non_protected_statuses(facility)).to eq(expected_statuses)
    end

    it "returns all non-reconciled statuses in cross-facility context" do
      expected_statuses = [
        root_statuses[:new],
        root_statuses[:in_process],
        root_statuses[:canceled],
        root_statuses[:complete],
      ]

      expect(described_class.non_protected_statuses(nil)).to eq(expected_statuses)
    end
  end

  describe "#state_name" do
    it "identifies the correct name for a root status" do
      expect(root_statuses[:in_process].state_name).to eq(:inprocess)
      expect(root_statuses[:canceled].state_name).to eq(:canceled)
    end

    it "uses the base status for a facility status" do
      status = create(:order_status, parent: root_statuses[:in_process])
      expect(status.state_name).to eq(:inprocess)
    end
  end

  describe "#self_and_descendants" do
    it "returns the root record and its children" do
      child_status = create(:order_status, parent: root_statuses[:canceled])
      expect(OrderStatus.canceled.self_and_descendants).to eq([
        root_statuses[:canceled],
        child_status,
      ])
    end
  end
end

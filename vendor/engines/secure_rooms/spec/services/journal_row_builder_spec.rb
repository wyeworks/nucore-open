# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalRowBuilder, :default_journal_row_converters, type: :service do
  let(:builder) { described_class.new(journal, order.order_details) }

  describe "#build" do
    let(:journal) { build(:journal, facility: facility, created_by: 1) }

    let(:facility) { create(:setup_facility) }
    let(:secure_room) { create(:secure_room, facility: facility) }
    let(:order) { create(:purchased_order, product: secure_room) }

    let!(:occupancy) do
      create(
        :occupancy,
        :complete,
        secure_room: secure_room,
        order_detail: order.order_details.first,
        account: order.account,
      )
    end

    before do
      order.order_details.each(&:to_complete!)
    end

    describe "row description" do
      subject { builder.build.journal_rows.first.description }
      it { is_expected.to include("#{secure_room.name} x1") }
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe LogEventMetadataPresenter do
  let(:facility) { create(:setup_facility) }
  let(:user) { create(:user, :administrator) }
  let(:statement) { create(:statement, facility:) }

  let(:deposit_number_label) { OrderDetail.human_attribute_name(:deposit_number) }
  let(:reconciled_note_label) { OrderDetail.human_attribute_name(:reconciled_note) }

  def presenter_for(metadata, event_type: :unreconciled, loggable: statement)
    described_class.new(LogEvent.log(loggable, event_type, user, metadata:))
  end

  describe "#details" do
    it "pairs each label with its joined values" do
      presenter = presenter_for(
        { deposit_numbers: ["TX-1", "TX-2"], reconciled_notes: ["Paid late", "Partial"] }
      )

      expect(presenter.details).to eq(
        [
          [deposit_number_label, "TX-1, TX-2"],
          [reconciled_note_label, "Paid late; Partial"],
        ]
      )
    end

    it "is empty when there is no metadata" do
      expect(presenter_for(nil).details).to eq([])
    end

    it "is empty for an unrelated event type" do
      presenter = presenter_for({ deposit_numbers: ["TX-1"] }, event_type: :closed)

      expect(presenter.details).to eq([])
    end
  end

  describe "#to_s" do
    it "renders the pairs as a single string" do
      presenter = presenter_for({ deposit_numbers: ["TX-1"], reconciled_notes: ["Paid late"] })

      expect(presenter.to_s).to eq(
        "#{deposit_number_label}: TX-1 #{reconciled_note_label}: Paid late"
      )
    end

    it "is blank when there are no details" do
      expect(presenter_for(nil).to_s).to eq("")
    end
  end
end

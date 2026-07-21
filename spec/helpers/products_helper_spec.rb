# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductsHelper do
  describe "#options_for_relay" do
    let(:subject) { options_for_relay }

    it(
      "list all relay types if none disabled",
      { feature_setting: { "products.disable_relay_synaccess_rev_a": false } }
    ) do
      expect(subject.to_h).to include(
        RelaySynaccessRevA,
        RelaySynaccessRevB,
        RelayDataprobe
      )
    end

    it(
      "exclude synaccess rev a if disabled flag is on",
      { feature_setting: { "products.disable_relay_synaccess_rev_a": true } }
    ) do
      expect(subject.to_h).to_not include(RelaySynaccessRevA)
    end
  end

  describe "#public_calendar_availability_options" do
    subject(:classes) { helper.send(:public_calendar_availability_options, instrument)[:class] }

    let(:instrument) { create(:setup_instrument) }

    it "is available when open now with no current reservation" do
      expect(classes).to include("available")
    end

    context "with a current reservation" do
      before do
        create(:purchased_reservation,
               reserve_start_at: 30.minutes.ago,
               reserve_end_at: 30.minutes.from_now,
               product: instrument)
      end

      it "is in use, not available" do
        expect(classes).to include("in-use")
        expect(classes).not_to include("available")
      end
    end

    context "with a current reservation on a schedule-sharing sibling" do
      before do
        sibling = create(:setup_instrument,
                         facility: instrument.facility,
                         schedule: instrument.schedule)
        create(:admin_reservation,
               reserve_start_at: 30.minutes.ago,
               reserve_end_at: 30.minutes.from_now,
               product: sibling)
      end

      it "marks this instrument in use too" do
        expect(classes).to include("in-use")
        expect(classes).not_to include("available")
      end
    end

    context "when closed now (no schedule rule covers the current time)" do
      before { instrument.schedule_rules.destroy_all }

      it "is not available" do
        expect(classes).to include("in-use")
        expect(classes).not_to include("available")
      end
    end

    context "on a holiday" do
      before { Holiday.create!(date: Time.current.to_date) }

      it "is not available when the instrument restricts holiday access" do
        instrument.update!(restrict_holiday_access: true)
        expect(classes).to include("in-use")
        expect(classes).not_to include("available")
      end

      it "stays available when the instrument does not restrict holiday access" do
        instrument.update!(restrict_holiday_access: false)
        expect(classes).to include("available")
      end
    end

    context "when offline" do
      before do
        create(:offline_reservation,
               product: instrument,
               reserve_start_at: 1.hour.ago,
               reserve_end_at: nil)
      end

      it "shows the offline note" do
        options = helper.send(:public_calendar_availability_options, instrument)
        expect(options[:title]).to eq(I18n.t("instruments.offline.note"))
      end
    end
  end
end

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
    subject(:options) { helper.send(:public_calendar_availability_options, instrument) }

    let(:instrument) { create(:setup_instrument) }

    it "marks an available instrument available" do
      expect(options[:class]).to include("available")
    end

    context "when not available now" do
      before do
        create(:purchased_reservation,
               reserve_start_at: 30.minutes.ago,
               reserve_end_at: 30.minutes.from_now,
               product: instrument)
      end

      it "marks it in use" do
        expect(options[:class]).to include("in-use")
        expect(options[:class]).not_to include("available")
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
        expect(options[:title]).to eq(I18n.t("instruments.offline.note"))
      end
    end
  end
end

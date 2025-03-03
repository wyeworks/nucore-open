# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductsHelper do
  describe "#options_for_relay" do
    let(:subject) { options_for_relay }

    it(
      "list all relay types if none disabled",
      { feature_setting: { disable_relay_synaccess_rev_a: false } }
    ) do
      expect(subject.to_h).to include(
        RelaySynaccessRevA,
        RelaySynaccessRevB,
        RelayDataprobe
      )
    end

    it(
      "exclude synaccess rev a if disabled flag is on",
      { feature_setting: { disable_relay_synaccess_rev_a: true } }
    ) do
      expect(subject.to_h).to_not include(RelaySynaccessRevA)
    end
  end
end

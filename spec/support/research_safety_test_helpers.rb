# frozen_string_literal: true

module ResearchSafetyTestHelpers

  def stub_research_safety_lookup(user, valid: [], invalid: [])
    api = double("ResearchSafetyAdapter")
    Array(valid).each { |certificate| expect(api).to receive(:certified?).with(certificate).and_return(true) }
    Array(invalid).each { |certificate| expect(api).to receive(:certified?).with(certificate).and_return(false) }
    allow(ResearchSafetyCertificationLookup).to receive(:adapter).with(user).and_return(api)
  end

end

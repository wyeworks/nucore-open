# frozen_string_literal: true

module ResearchSafetyTestHelpers

  # Some controller actions call `certified?` more than one time, for example when a
  # reservation is successfully created. So the `number_of_times` the stub can be
  # called may need to be greater than one
  def stub_research_safety_lookup(user, valid: [], invalid: [], number_of_times: 1)
    api = double("ResearchSafetyAdapter")
    Array(valid).each { |certificate| expect(api).to receive(:certified?).exactly(number_of_times).with(certificate).and_return(true) }
    Array(invalid).each { |certificate| expect(api).to receive(:certified?).exactly(number_of_times).with(certificate).and_return(false) }
    allow(ResearchSafetyCertificationLookup).to receive(:adapter).with(user).and_return(api)
  end

end

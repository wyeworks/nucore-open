# frozen_string_literal: true

RSpec::Matchers.define :have_content_i do |expected|
  match do |actual|
    actual.text =~ /#{Regexp.quote expected}/i
  end

  failure_message do |actual|
     "expected to find text #{expected.inspect} (case ignored) in #{actual.text.inspect}"
  end

  failure_message_when_negated do |actual|
    "expected to not to find text #{expected.inspect} (case ignored) in #{actual.text.inspect}"
  end
end

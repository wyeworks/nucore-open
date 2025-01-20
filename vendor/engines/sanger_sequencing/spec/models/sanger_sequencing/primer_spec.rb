# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::Primer do
  describe "#default_list" do
    let(:subject) { described_class.default_list }

    it { is_expected.to be_an Array }
    it { expect(subject.all?(String)).to be true }
  end
end

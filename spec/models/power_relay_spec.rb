# frozen_string_literal: true

require "rails_helper"

class SomeRelay < Relay

  include PowerRelay

end

RSpec.describe SomeRelay do

  it { is_expected.to validate_presence_of :ip }
  it { is_expected.to validate_presence_of :outlet }
  it { is_expected.to validate_presence_of :username }
  it { is_expected.to validate_presence_of :password }
  it { is_expected.not_to validate_presence_of :auto_logout_minutes }

  describe "outlet range" do
    let(:relay) { SomeRelay.new(ip: "123", username: "nucore", password: "password") }

    it "allows a range of 1-16 outlets" do
      relay.outlet = 16

      expect(relay).to be_valid
    end

    it "does not allow more than 17 outlets" do
      relay.outlet = 17

      expect(relay).to be_invalid
      expect(relay.errors[:outlet]).to include(/less than or equal to/)
    end
  end

  describe "ip port allocation" do
    let(:relay) { SomeRelay.new(ip: "123", username: "nucore", password: "password", outlet: 1, instrument_id: 1) }

    it "allows a numerical port allocation" do
      relay.ip_port = 3000

      expect(relay).to be_valid
    end

    it "does not allow an alphanumeric port allocation" do
      relay.ip_port = "three thousand"

      expect(relay).to be_invalid
      expect(relay.errors[:ip_port]).to include(/not a valid number/)
    end

    it "allows a nil value" do
      relay.ip_port = nil

      expect(relay).to be_valid
    end
  end

  context "with auto logout" do
    before { subject.auto_logout = true }
    it { is_expected.to validate_presence_of :auto_logout_minutes }
  end
end

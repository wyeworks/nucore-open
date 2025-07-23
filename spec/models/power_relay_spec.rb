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
  it { is_expected.not_to validate_presence_of :secondary_outlet }

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

  describe "secondary outlet" do
    let(:relay) { SomeRelay.new(ip: "123", username: "nucore", password: "password", outlet: 1, instrument_id: 1) }

    it "allows a secondary outlet allocation" do
      relay.secondary_outlet = 3

      expect(relay).to be_valid
    end
  end

  context "with auto logout" do
    before { subject.auto_logout = true }
    it { is_expected.to validate_presence_of :auto_logout_minutes }
  end

  describe "retries to query status" do
    let(:relay) { SomeRelay.new(ip: "123", username: "nucore", password: "password", outlet: 1, instrument_id: 1) }
    let(:relay_connection) { double("RelayConnection") }

    before do
      allow(relay).to receive(:relay_connection).and_return(relay_connection)
    end

    it "retries once if NetBooter::Error is raised, then succeeds" do
      call_count = 0
      allow(relay_connection).to receive(:status) do
        call_count += 1
        raise NetBooter::Error if call_count == 1
        true
      end
      expect(relay.query_status).to eq(true)
      expect(call_count).to eq(2)
    end

    it "raises if NetBooter::Error is raised twice" do
      allow(relay_connection).to receive(:status).and_raise(NetBooter::Error)
      expect { relay.query_status }.to raise_error(NetBooter::Error)
    end
  end
end

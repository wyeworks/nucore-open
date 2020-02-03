# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dataprobe::Ipio do
  let(:ip) { "192.168.10.15" }
  let(:fake_socket) { double "TCPSocket", read_nonblock: nil, write_nonblock: nil, close: nil }
  let(:message_number) { 17 }

  subject(:relay) { described_class.new(ip) }

  before(:each) do
    allow(Socket).to receive(:tcp).and_return(fake_socket)
    allow(fake_socket).to receive(:read_nonblock).with(2).and_return([message_number].pack("s<"))
  end

  describe ".new" do
    it "sets ip from its first argument" do
      expect(described_class.new(ip).ip).to eq ip
    end

    it "sets port to 9100" do
      expect(described_class.new(ip).port).to eq 9100
    end

    it "sets username from the passed-in options and encodes it" do
      expect(described_class.new(ip, username: "alice").username).to eq "alice".ljust(21, "\x00")
    end

    it "defaults username to 'user'" do
      expect(described_class.new(ip).username).to eq "user".ljust(21, "\x00")
    end

    it "sets password from the passed-in options and encodes it" do
      expect(described_class.new(ip, password: "abc123").password).to eq "abc123".ljust(21, "\x00")
    end

    it "defaults password to 'user'" do
      expect(described_class.new(ip).password).to eq "user".ljust(21, "\x00")
    end
  end

  describe "#toggle" do
    before(:each) do
      allow(fake_socket).to receive(:read_nonblock).with(1).and_return("\x00")
    end

    it "opens a TCP connection to the appropriate host and port with a 5-second connection timeout" do
      expect(Socket).to receive(:tcp).with(ip, 9100, connect_timeout: 5)
      relay.toggle(1, true)
    end

    it "performs a handshake" do
      expect(fake_socket).to receive(:write_nonblock).with("hello-000\x00")
      relay.toggle(1, true)
    end

    it "sends a message with the next message number to set the outlet’s status" do
      authentication = ["\x03", "user".ljust(21, "\x00"), "user".ljust(21, "\x00")].join
      toggle_message = ["\x01\x00", [message_number + 1].pack("s<"), [4].pack("C"), [1].pack("C")].join
      expect(fake_socket).to receive(:write_nonblock).with("#{authentication}#{toggle_message}")
      relay.toggle(4, true)
    end

    it "raises an error if it reads an unexpected response after sending the message" do
      allow(fake_socket).to receive(:read_nonblock).with(1).and_return("unexpected")
      expect { relay.toggle(4, false) }.to raise_error(Dataprobe::Error)
    end

    it "returns its second argument" do
      expect(relay.toggle(4, false)).to be false
    end
  end

  describe "#status" do
    before(:each) do
      allow(fake_socket).to receive(:read_nonblock).with(100).and_return(([1]*100).pack("C*"))
    end

    it "opens a TCP connection to the appropriate host and port with a 5-second connection timeout" do
      expect(Socket).to receive(:tcp).with(ip, 9100, connect_timeout: 5)
      relay.status(2)
    end

    it "performs a handshake" do
      expect(fake_socket).to receive(:write_nonblock).with("hello-000\x00")
      relay.status(2)
    end

    it "sends a message with the next message number to check the relay’s status" do
      authentication = ["\x03", "user".ljust(21, "\x00"), "user".ljust(21, "\x00")].join
      status_message = ["\x04\x00", [message_number + 1].pack("s<")].join
      expect(fake_socket).to receive(:write_nonblock).with("#{authentication}#{status_message}")
      relay.status(2)
    end

    it "reads 100 bytes as a response" do
      expect(fake_socket).to receive(:read_nonblock).with(100)
      relay.status(2)
    end

    it "returns whether the status of the appropriate outlet (which is 1-indexed) is 1" do
      statuses = [1, 0]*50
      allow(fake_socket).to receive(:read_nonblock).with(100).and_return(statuses.pack("C*"))
      expect(relay.status(2)).to be false
    end
  end
end

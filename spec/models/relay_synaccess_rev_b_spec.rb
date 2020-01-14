# frozen_string_literal: true

require "rails_helper"

RSpec.describe RelaySynaccessRevB do
  let(:relay) { FactoryBot.build(:relay_synb, outlet: 1, ip: "192.168.10.20", username: "admin", password: "admin") }
  let(:body) { File.new(File.expand_path("../files/relays/synaccess_rev_b_status.xml", __dir__)) }

  it "talks on port 80 by default" do
    stub_request(:get, "http://192.168.10.20/status.xml").with(
      basic_auth: ["admin", "admin"]
    ).to_return(body: body, status: 200)

    expect(relay.get_status).to eq(true)
  end

  it "can talk to another port" do
    stub_request(:get, "http://192.168.10.20:9100/status.xml").with(
      basic_auth: ["admin", "admin"]
    ).to_return(body: body, status: 200)

    relay.ip_port = 9100
    expect(relay.get_status).to eq(true)
  end

end

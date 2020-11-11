# frozen_string_literal: true

require "rails_helper"

RSpec.describe LdapAuthentication::UserUpdater do
  let(:net_ldap_entry) do
    double(
      "Fake::Net::LDAP::Entry",
      givenname: ["First"],
      sn: ["Last"],
      uid: ["uname"],
      mail: ["primary@example.org", "secondary@example.org"],
    )
  end
  let(:user_entry) { LdapAuthentication::UserEntry.new(net_ldap_entry) }

  before do
    allow(LdapAuthentication::UserEntry).to receive(:find).with("abc123").and_return(user_entry)
    allow(LdapAuthentication::UserEntry).to receive(:find).with("xyz789").and_return(nil)
  end

  it "updates the attributes after successful ldap authentication" do
    user = create(:user, username: "abc123")
    described_class.new(user).update_from_ldap
    user.reload

    expect(user.first_name).to eq("First")
    expect(user.last_name).to eq("Last")
    expect(user.email).to eq("primary@example.org")
  end

  context "when an attrubute is missing" do
    let!(:user) { create(:user, username: "abc123", email: "primary@example.org") }
    let(:net_ldap_entry) do
      double(
        "Fake::Net::LDAP::Entry",
        givenname: ["First"],
        sn: ["Last"],
        uid: ["uname"],
        mail: [],
      )
    end

    it "updates attrubutes that are present in the response" do
      expect { described_class.new(user).update_from_ldap }.to change { user.first_name }
    end

    it "does not update attrubute that are not present in the response" do
      expect { described_class.new(user).update_from_ldap }.not_to change { user.email }
    end
  end

  it "raises an error if the user is not found" do
    user = create(:user, username: "xyz789")
    expect { described_class.new(user).update_from_ldap }.to raise_error(/not found in LDAP/)
  end

  describe "a validation error" do
    let!(:old_user) { create(:user, email: "primary@example.org") }
    let!(:user) { create(:user, email: "old@example.org", username: "abc123") }

    it "triggers a notification" do
      expect(ActiveSupport::Notifications).to receive(:instrument).with("background_error", a_hash_including(information: /Could not update User/))

      described_class.new(user).update_from_ldap
    end

    it "does not update the user's information" do
      described_class.new(user).update_from_ldap
      user.reload
      expect(user.email).to eq("old@example.org")
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe LdapAuthentication::UserEntry do
  let(:net_ldap_entry) do
    double(
      "Fake::Net::LDAP::Entry",
      givenname: ["First"],
      sn: ["Last"],
      uid: ["uname"],
      mail: ["primary@example.org", "secondary@example.org"],
    )
  end
  let(:user_entry) { described_class.new(net_ldap_entry) }

  describe ".find" do
    let(:admin_ldap) { spy("AdminConnection", search: [net_ldap_entry]) }
    before { allow(LdapAuthentication).to receive(:admin_connection) { admin_ldap } }

    it "returns a UserEntry" do
      entry = described_class.find("uname")
      expect(entry).to be_an_instance_of(described_class)
      expect(admin_ldap).to have_received(:search).with(filter: Net::LDAP::Filter.eq("uid", "uname"))
    end

    describe "retrying" do
      it "raise an error if it fails 3 times" do
        expect(admin_ldap).to(receive(:search).exactly(3).times { raise(Net::LDAP::Error, "Connection timed out") })

        expect { described_class.find("uname") }.to raise_error(Net::LDAP::Error, "Connection timed out")
      end

      it "succeeds if it succeeds the third time" do
        expect(admin_ldap).to(receive(:search).twice { raise(Net::LDAP::Error, "Connection timed out") })
        expect(admin_ldap).to(receive(:search).once { [net_ldap_entry] })

        entry = described_class.find("uname")
        expect(entry).to be_an_instance_of(described_class)
      end
    end
  end

  describe "fields" do
    it "gets first_name" do
      expect(user_entry.first_name).to eq("First")
    end

    it "gets last_name" do
      expect(user_entry.last_name).to eq("Last")
    end

    it "gets email" do
      expect(user_entry.email).to eq("primary@example.org")
    end

    it "gets the username" do
      expect(user_entry.username).to eq("uname")
    end
  end

  describe "to_user" do
    let(:user) { user_entry.to_user }

    it "returns a user" do
      expect(user).to be_an_instance_of(::User)
    end

    it "is not persisted" do
      expect(user).to be_new_record
    end

    it "has the email set" do
      expect(user.email).to eq("primary@example.org")
    end

    it "has the first name set" do
      expect(user.first_name).to eq("First")
    end

    it "has the last name set" do
      expect(user.last_name).to eq("Last")
    end

    it "has the username set" do
      expect(user.username).to eq("uname")
    end
  end

  describe "attributes" do
    it "fills out the attribute hash" do
      expect(user_entry.attributes).to include(
        username: "uname",
        first_name: "First",
        last_name: "Last",
        email: "primary@example.org",
      )
    end

    context "with an empty value" do
      let(:net_ldap_entry) do
        double(
          "Fake::Net::LDAP::Entry",
          givenname: [""],
          sn: ["Last"],
          uid: ["uname"],
          mail: ["primary@example.org", "secondary@example.org"],
        )
      end

      it "excludes the attribute" do
        expect(user_entry.attributes.keys).not_to include(:first_name)
      end
    end
  end
end

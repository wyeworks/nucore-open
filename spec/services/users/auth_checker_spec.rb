require "rails_helper"

RSpec.describe Users::AuthChecker do

  describe "#authenticated?" do
    context "with an external user", feature_setting: { bypass_kiosk_auth: false } do
      let(:user) { create(:user, :external, email: "external@example.org", username: "external@example.org") }

      context "with the correct password" do
        let(:auth_user) { described_class.new(user, "P@ssw0rd!!") }

        it "returns true" do
          expect(auth_user.authenticated?).to eq true
        end
      end

      context "with the wrong password" do
        let(:auth_user) { described_class.new(user, "WRONGP@ssw0rd!!") }

        it "returns false" do
          expect(auth_user.authenticated?).to eq false
        end
      end
    end

    context "with a netid user", :ldap, feature_setting: { uses_ldap_authentication: true, bypass_kiosk_auth: false } do
      let(:user) { create(:user, :netid, email: "internal@example.org", username: "netid") }

      before(:each) do
        expect(auth_user).to receive(:ldap_enabled?).and_return(true)
      end

      context "with the correct password" do
        let(:auth_user) { described_class.new(user, "netidpassword") }

        it "returns true" do
          expect(auth_user.authenticated?).to eq true
        end
      end

      context "with the wrong password" do
        let(:auth_user) { described_class.new(user, "wrong") }

        it "returns false" do
          expect(auth_user.authenticated?).to eq false
        end
      end
    end

    context "with a netid user and no LdapAuthentication gem", feature_setting: { bypass_kiosk_auth: false } do
      let(:user) { create(:user, :netid, email: "internal@example.org", username: "netid") }

      context "with the correct password" do
        let(:auth_user) { described_class.new(user, "netidpassword") }

        it "returns nil" do
          expect(auth_user.authenticated?).to eq nil
        end
      end

      context "with the wrong password" do
        let(:auth_user) { described_class.new(user, "wrong") }

        it "returns nil" do
          expect(auth_user.authenticated?).to eq nil
        end
      end
    end

    context "with kiosk auth bypass", feature_setting: { bypass_kiosk_auth: true } do
      let(:user) { create(:user, :external, email: "external@example.org", username: "external@example.org") }

      context "with the correct password" do
        let(:auth_user) { described_class.new(user, "netidpassword") }

        it "returns true" do
          expect(auth_user.authenticated?).to eq true
        end
      end

      context "with the wrong password" do
        let(:auth_user) { described_class.new(user, "wrong") }

        it "returns true" do
          expect(auth_user.authenticated?).to eq true
        end
      end
    end

  end

end

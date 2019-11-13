require "rails_helper"

RSpec.describe Users::ConvertInternalToExternalUser do
  let!(:converter) { described_class.new(user.username) }

  describe "successfully converting" do
    let(:user) { create(:user, username: "int123", email: "int@example.org") }

    it "converts the username" do
      expect { converter.convert! }.to change { user.reload.username }.to("int@example.org")
    end

    it "sets a random password" do
      expect { converter.convert! }.to change { user.reload.encrypted_password }.to be_present
    end
  end

  describe "the user is already external" do
    let(:user) { create(:user, username: "ext123@example.org", email: "ext123@example.org") }

    it "errors" do
      expect { converter.convert! }.to raise_error(/already an external/)
    end
  end
end

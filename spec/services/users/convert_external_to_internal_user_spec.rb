require "rails_helper"

RSpec.describe Users::ConvertExternalToInternalUser do

  describe "successful conversion" do
    let(:user) { create(:user, email: "external@example.org", username: "external@example.org", password: "something") }
    let(:converter) { described_class.new(user.email, "netid") }

    it "updates the username" do
      expect { converter.convert! }.to change { user.reload.username }.to("netid")
    end

    it "clears the password" do
      expect { converter.convert! }.to change { user.reload.encrypted_password }.to be_blank
    end

    it "does not change the first_name" do
      expect { converter.convert! }.not_to change { user.reload.first_name }
    end

    it "does not change the last_name" do
      expect { converter.convert! }.not_to change { user.reload.last_name }
    end
  end

  describe "when the username already exists in the database" do
    let(:user) { create(:user, email: "external@example.org", username: "external@example.org", password: "something") }
    let!(:existing_user) { create(:user, username: "netid") }
    let(:converter) { described_class.new(user.email, "netid") }

    it "errors" do
      expect { converter.convert! }.to raise_error(/Username has already been taken/)
    end
  end

  describe "when the lookup updates the email and name" do
    class TestUpdatingLookup
      def call(username)
        User.new(username: username, email: "newemail@example.org", first_name: "New")
      end
    end

    let(:user) { create(:user, email: "external@example.org", username: "external@example.org", last_name: "Old") }
    let(:converter) { described_class.new(user.email, "netid", lookup: TestUpdatingLookup.new) }

    it "updates everything" do
      converter.convert!
      expect(user.reload).to have_attributes(
        email: "newemail@example.org",
        username: "netid",
        first_name: "New",
        last_name: "Old",
      )
    end
  end

  describe "when the lookup finds nothing" do
    class TestEmptyLookup
      def call(_username)
      end
    end

    let(:user) { create(:user, email: "external@example.org", username: "external@example.org") }
    let(:converter) { described_class.new(user.email, "notfound", lookup: TestEmptyLookup.new) }

    it "raises an error" do
      expect { converter.convert! }.to raise_error(/not found in directory/)
    end
  end

end

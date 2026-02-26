# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountSearcher do
  describe "valid?" do
    it "is valid if you have three characters" do
      searcher = described_class.new("abc")
      expect(searcher).to be_valid
    end

    it "is invalid if you are searching for two characters" do
      searcher = described_class.new("ab")
      expect(searcher).not_to be_valid
    end
  end

  describe "results" do
    let(:owner) { create(:user, first_name: "Myfirst", last_name: "Mylast", username: "Myuser", email: "myemail@example.com") }
    let!(:account) { create(:account, :with_account_owner, owner: owner, account_number: "123456", description: "Mydescription", ar_number: "ARNUMBER") }

    it "matches the account number" do
      expect(described_class.new("123456").results).to eq([account])
    end

    it "matches part of the account number" do
      expect(described_class.new("345").results).to eq([account])
    end

    it "matches the owner's first name" do
      expect(described_class.new("Myfirst").results).to eq([account])
    end

    it "matches part of the owner's first name" do
      expect(described_class.new("first").results).to eq([account])
    end

    it "matches the owner's last name" do
      expect(described_class.new("mylast").results).to eq([account])
    end

    describe "with a purchaser as well" do
      let(:purchaser) { create(:user, username: "Iampurchaser") }
      let!(:purchaser_account_user) { create(:account_user, :purchaser, user: purchaser, account: account) }

      it "does not find the account" do
        expect(described_class.new("purchaser").results).to be_blank
      end

      it "returns only a single result" do
        expect(described_class.new("last").results).to eq([account])
      end
    end

    it "matches part of the owner's last name" do
      expect(described_class.new("last").results).to eq([account])
    end

    it "matches the owner's username" do
      expect(described_class.new("myuser").results).to eq([account])
    end

    it "matches part of the owner's username" do
      expect(described_class.new("user").results).to eq([account])
    end

    it "matches a full name" do
      expect(described_class.new("myfirst mylast").results).to eq([account])
    end

    it "matches a partial name with extra spaces in the middle" do
      expect(described_class.new("myf      myla").results).to eq([account])
    end

    describe "matches both owner and account" do
      before { account.update!(account_number: "Myuser") }

      it "only returns one" do
        expect(described_class.new("myuser").results).to eq([account])
      end
    end

    it "does not search by owner email" do
      expect(described_class.new("myemail@example.com").results).to be_empty
    end

    it "matches by description" do
      expect(described_class.new("mydesc").results).to eq([account])
    end

    it "matches by AR number" do
      expect(described_class.new("ARNUM").results).to eq([account])
    end

    it "returns nothing when nothing matches" do
      expect(described_class.new("RANDOM").results).to be_empty
    end

    describe "when there's an account that matches another facility" do
      let(:facility) { create(:facility) }
      let!(:other_account) { create(:account, :with_account_owner, account_number: account.account_number, facilities: [facility], owner: owner) }

      before(:each) do
        allow(Account.config).to receive(:global_account_types).and_return([])
        allow(Account.config).to receive(:facility_account_types).and_return(["Account"])
      end

      it "returns both with no restrictions" do
        expect(described_class.new(account.account_number).results).to contain_exactly(account, other_account)
      end

      it "only account for the specified facility" do
        expect(described_class.new(account.account_number, scope: Account.for_facility(facility)).results).to eq([other_account])
      end
    end
  end

  describe "filter_params", :use_test_account, feature_setting: { account_tabs: true } do
    let(:user) { create(:user) }
    let(:facility) { Facility.cross_facility }
    let!(:suspended_account) do
      create(
        :test_account,
        :with_account_owner,
        created_by: user.id,
        suspended_at: Time.current,
      )
    end
    let!(:active_account) do
      create(:test_account, :with_account_owner, created_by: user.id)
    end

    context "with suspended filter" do
      let(:searcher) do
        described_class.new("", scope: Account.all, filter_params: { suspended: "true" })
      end

      it "includes suspende account" do
        expect(searcher.results).to match([suspended_account])
      end
    end

    context "with account_status active filter" do
      let(:searcher) do
        described_class.new("", scope: Account.all, filter_params: { account_status: "active" })
      end

      it "only includes active accounts" do
        expect(searcher.results).to match([active_account])
      end
    end
  end

end

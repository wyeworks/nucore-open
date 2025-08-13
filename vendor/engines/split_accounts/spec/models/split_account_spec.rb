# frozen_string_literal: true

require "rails_helper"
require_relative "../split_accounts_spec_helper"

RSpec.describe SplitAccounts::SplitAccount, :enable_split_accounts, type: :model do
  it "is an account type" do
    expect(described_class.new).to be_an(Account)
  end

  # TODO: remove this if/when we do factory linting
  it "has a valid factory" do
    expect(build(:split_account)).to be_valid
  end

  describe "validations" do
    let(:subaccount_1) { build_stubbed(:setup_account) }
    let(:subaccount_2) { build_stubbed(:setup_account) }

    context "when only one split" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 100, apply_remainder: true, parent_split_account: split_account)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        expect(split_account.errors[:splits]).to include(I18n.t("activerecord.errors.models.split_accounts/split_account.attributes.splits.more_than_one_split"))
      end
    end

    context "when splits total 100 and one split has apply_remainder" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: subaccount_1)
          split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account, subaccount: subaccount_2)
        end
      end

      it "is valid" do
        expect(split_account).to be_valid
      end
    end

    context "when splits do not total 100 and one split has apply_remainder" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: subaccount_1)
          split_account.splits << build(:split, percent: 49.99, apply_remainder: false, parent_split_account: split_account, subaccount: subaccount_2)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        message = I18n.t("activerecord.errors.models.split_accounts/split_account.attributes.splits.percent_total")
        expect(split_account.errors[:splits]).to include(message)
      end
    end

    context "when splits total 100 and no splits have apply_remainder" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account, subaccount: subaccount_1)
          split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account, subaccount: subaccount_2)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        message = I18n.t("activerecord.errors.models.split_accounts/split_account.attributes.splits.only_one_apply_remainder")
        expect(split_account.errors[:splits]).to include(message)
      end
    end

    context "when splits total 100 and multiple splits have apply_remainder" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: subaccount_1)
          split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: subaccount_2)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        message = I18n.t("activerecord.errors.models.split_accounts/split_account.attributes.splits.only_one_apply_remainder")
        expect(split_account.errors[:splits]).to include(message)
      end
    end

    context "when splits share one or more subaccount" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: subaccount_1)
          split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account, subaccount: subaccount_1)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        message = I18n.t("activerecord.errors.models.split_accounts/split_account.attributes.splits.duplicate_subaccounts")
        expect(split_account.errors[:splits]).to include(message)
      end
    end
  end

  describe "#percent_total" do
    let(:split_account) do
      described_class.new.tap do |split_account|
        split_account.splits.build(percent: 25)
        split_account.splits.build(percent: 50.1)
      end
    end

    let(:sum) { BigDecimal("75.1") }

    it "is a BigDecimal" do
      expect(split_account.percent_total).to be_a(BigDecimal)
    end

    it "sums the percent of each split" do
      expect(split_account.percent_total).to eq(sum)
    end
  end

  describe "#apply_remainder_count" do
    let(:split_account) do
      described_class.new.tap do |split_account|
        split_account.splits.build(apply_remainder: true)
        split_account.splits.build(apply_remainder: true)
        split_account.splits.build(apply_remainder: false)
      end
    end

    it "counts splits with extra penny" do
      expect(split_account.apply_remainder_count).to eq(2)
    end
  end

  describe "has_many subaccounts" do
    let(:split_account) { create(:split_account) }

    it "returns subaccounts" do
      expect(split_account.subaccounts).to contain_exactly(*split_account.splits.map(&:subaccount))
    end
  end

  describe "#suspended?" do
    context "when subaccounts and parent account are not suspended" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: create(:setup_account))
          split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account, subaccount: create(:setup_account))
          split_account.save!
        end
      end

      it "does not suspend parent split_account" do
        expect(split_account).not_to be_suspended
      end
    end

    context "when parent account is suspended, but the children are not" do
      let(:split_account) do
        build(:split_account, without_splits: true, suspended_at: Time.current).tap do |split_account|
          split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: create(:setup_account))
          split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account, subaccount: create(:setup_account))
          split_account.save!
        end
      end

      it "suspends parent split_account" do
        expect(split_account).to be_suspended
      end
    end

    context "when any subaccount is suspended" do
      let(:suspended_at) { 1.day.ago.change(usec: 0) }
      let(:suspended_subaccount) { build(:setup_account, suspended_at: suspended_at) }

      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: suspended_subaccount)
          split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account, subaccount: create(:setup_account))
          split_account.save!
        end
      end

      it "suspends the parent split_account" do
        expect(split_account).to be_suspended
        expect(split_account.suspended_at).to eq(suspended_at)
      end

      context "when subaccount unsuspends" do
        before do
          split_account
          suspended_subaccount.unsuspend
        end

        it "keeps parent split_account suspended" do
          expect(split_account.reload).to be_suspended
        end

        context "and the child gets re-suspend" do
          before do
            suspended_subaccount.reload.suspend
          end

          it "keeps the original suspended_at" do
            expect(split_account.reload.suspended_at).to eq(suspended_at)
          end
        end
      end
    end
  end

  describe "#expired?" do
    context "when subaccounts and parent account are not expired" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: create(:setup_account))
          split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account, subaccount: create(:setup_account))
          split_account.save
        end
      end

      it "does not expire parent split_account" do
        expect(split_account).not_to be_expired
      end
    end

    context "when any subaccount is expired" do
      let(:expired_subaccount) { build(:setup_account, expires_at: 1.day.ago) }

      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: expired_subaccount)
          split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account, subaccount: create(:setup_account))
          split_account.save
        end
      end

      it "expires the parent split_account" do
        expect(split_account).to be_expired
      end

      context "when subaccount unexpires" do
        before do
          split_account
          expired_subaccount.expires_at = Time.current + 1.year
          expired_subaccount.save
        end

        it "unexpires the parent split_account" do
          expect(split_account.reload).not_to be_expired
        end
      end
    end
  end

  describe "#earliest_suspended_subaccount" do
    context "with a suspended subaccount and an unsuspended subaccount" do
      let(:suspended_subaccount) { build_stubbed(:setup_account, suspended_at: 1.day.ago) }
      let(:unsuspended_subaccount) { build_stubbed(:setup_account, suspended_at: nil) }

      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: suspended_subaccount)
          split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account, subaccount: unsuspended_subaccount)
        end
      end

      it "returns earliest suspended subaccount" do
        expect(split_account.earliest_suspended_subaccount).to eq(suspended_subaccount)
      end
    end

    context "without a suspended subaccount" do
      let(:unsuspended_subaccount) { build_stubbed(:setup_account, suspended_at: nil) }
      let(:unsuspended_subaccount2) { build_stubbed(:setup_account, suspended_at: nil) }

      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: unsuspended_subaccount)
          split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account, subaccount: unsuspended_subaccount2)
        end
      end

      it "returns nil" do
        expect(split_account.earliest_suspended_subaccount).to be_nil
      end
    end
  end
end

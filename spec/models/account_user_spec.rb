# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountUser do

  context "when creating through Account" do
    subject(:account) { build(:nufs_account, :with_account_owner) }

    it { is_expected.to be_valid }
  end

  context "with a valid user_role" do
    described_class.user_roles.each do |role|
      context role do
        subject { build(:account_user, user_role: role) }

        it "does not have an error on the role" do
          subject.valid?
          expect(subject.errors).not_to include(:user_role)
        end
      end
    end
  end

  context "with a blank user_role" do
    subject(:account_user) { build(:account_user, user_role: nil) }

    it "is invalid" do
      is_expected.not_to be_valid
      expect(account_user.errors).to be_added(:user_role, "is invalid")
    end
  end

  context "with an invalid user_role" do
    subject(:account_user) { build(:account_user, user_role: "Not A Role") }

    it "is invalid" do
      is_expected.not_to be_valid
      expect(account_user.errors).to be_added(:user_role, "is invalid")
    end
  end

  context "when a user has an active role for an account" do
    let(:account) { create(:nufs_account, :with_account_owner, owner: user) }
    let(:user) { create(:user) }

    context "when creating another role for the user for the account" do
      subject(:account_user) do
        build(:account_user, :purchaser, account: account, user: user)
      end

      it "is invalid" do
        is_expected.not_to be_valid
        expect(account_user.errors[:user_id])
          .to include(a_string_matching("already a member"))
      end
    end
  end

  context "when a user has inactive (deleted) roles for an account" do
    let(:account) { create(:nufs_account, :with_account_owner) }
    let(:user) { create(:user) }

    before(:each) do
      create(:account_user, :purchaser, :inactive, account: account, user: user)
    end

    context "when creating an identical active role" do
      subject(:account_user) do
        build(:account_user, :purchaser, account: account, user: user)
      end

      it { is_expected.to be_valid }
    end
  end

  describe "when there is already an inactive role" do
    let(:account) { create(:nufs_account, :with_account_owner) }
    let(:user) { create(:user) }

    it "can have multiple inactive roles for an account" do
      create(:account_user, :purchaser, :inactive, account: account, user: user)
      old = build(:account_user, :purchaser, :inactive, account: account, user: user)
      expect(old).to be_valid
    end
  end

  context "when an account has an active owner" do
    let!(:account) { create(:nufs_account, :with_account_owner) }

    context "when attempting to add another owner" do
      subject(:account_user) do
        build(:account_user, :owner, account: account, user: user)
      end
      let(:user) { create(:user) }

      it "is invalid" do
        is_expected.not_to be_valid
        expect(account_user.errors[:user_role])
          .to include(a_string_matching("already been taken"))
      end
    end
  end

  describe "can have multiple old owners" do
    let!(:account) { create(:nufs_account, :with_account_owner) }

    it "in valid" do
      create(:account_user, :owner, :inactive, account: account, user: create(:user))
      old = build(:account_user, :owner, :inactive, account: account, user: create(:user))

      expect(old).to be_valid
    end
  end

  describe ".selectable_user_roles" do
    let(:facility) { create(:facility) }

    context "when supplying a user who will grant the role" do
      context "who is a facility director (manager)" do
        let(:user) { create(:user, :facility_director, facility: facility) }

        context "and a facility" do
          subject(:roles) { described_class.selectable_user_roles(user, facility) }

          it { is_expected.to include(AccountUser::ACCOUNT_OWNER) }
        end

        context "but no facility" do
          subject(:roles) { described_class.selectable_user_roles(user) }

          it { is_expected.not_to include(AccountUser::ACCOUNT_OWNER) }
        end
      end

      context "who is an account manager" do
        subject(:roles) do
          described_class.selectable_user_roles(user, Facility.cross_facility)
        end
        let(:user) { create(:user, :account_manager) }

        it { is_expected.to include(AccountUser::ACCOUNT_OWNER) }
      end
    end

    context "when not supplying a user" do
      context "but supplying a facility" do
        subject(:roles) { described_class.selectable_user_roles(nil, facility) }

        it { is_expected.not_to include(AccountUser::ACCOUNT_OWNER) }
      end

      context "or a facility" do
        subject(:roles) { described_class.selectable_user_roles }

        it { is_expected.not_to include(AccountUser::ACCOUNT_OWNER) }
      end
    end
  end

  describe ".grant" do
    let(:account_manager) { create(:user, :administrator) }
    let!(:account) { create(:nufs_account, :with_account_owner) }
    let(:new_purchaser) { create(:user) }

    it "creates a new UserRole when adding a purchaser" do
      result = described_class.grant(new_purchaser, AccountUser::ACCOUNT_PURCHASER, account, by: account_manager)
      expect(result).to be_persisted
      expect(result).to have_attributes(
        user: new_purchaser,
        account: account,
        user_role: AccountUser::ACCOUNT_PURCHASER,
        created_by_user: account_manager,
      )
    end

    it "will still create the purchaser if the account is invalid per the validator" do
      allow_any_instance_of(AccountValidator::ValidatorFactory.validator_class)
        .to receive(:account_is_open!).and_raise(AccountValidator::ValidatorError)

      result = described_class.grant(new_purchaser, AccountUser::ACCOUNT_PURCHASER, account, by: account_manager)
      expect(result).to be_persisted
    end

    it "replaces the owner if you add a new one" do
      old_owner = account.owner_user

      expect { described_class.grant(new_purchaser, AccountUser::ACCOUNT_OWNER, account, by: account_manager) }
        .to change { account.reload.owner_user }.from(old_owner).to(new_purchaser)
    end

    it "soft deletes the old owner" do
      old_owner_role = account.owner
      expect { described_class.grant(new_purchaser, AccountUser::ACCOUNT_OWNER, account, by: account_manager) }
        .to change(old_owner_role, :deleted_at).to be_present
    end

    it "does not persist if there's something wrong with it" do
      old_owner_role = account.owner
      result = described_class.grant(nil, AccountUser::ACCOUNT_OWNER, account, by: account_manager)
      expect(result).to be_new_record
      expect(old_owner_role.reload.deleted_at).to be_blank
    end

    it "creates a new row and deletes the old one when changing the role" do
      purchaser_account_user = described_class.grant(new_purchaser, AccountUser::ACCOUNT_PURCHASER, account, by: account_manager)
      ba_account_user = described_class.grant(new_purchaser, AccountUser::ACCOUNT_ADMINISTRATOR, account, by: account_manager)

      expect(purchaser_account_user).not_to eq(ba_account_user)
      expect(purchaser_account_user.reload.deleted_at).to be_present
    end
  end
end

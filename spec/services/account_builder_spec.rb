# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountBuilder, type: :service do

  describe ".new" do
    let(:instance) { described_class.new(options) }

    let(:options) do
      {
        account: build_stubbed(:setup_account),
        account_type: "NufsAccount",
        account_params_key: "nufs_account",
        current_user: build_stubbed(:user),
        facility: build_stubbed(:facility),
        owner_user: build_stubbed(:user),
        params: ActionController::Parameters.new(foo: "bar"),
      }
    end

    it "assigns account" do
      expect(instance.account).to eq(options[:account])
    end

    it "assigns account_type" do
      expect(instance.account_type).to eq(options[:account_type])
    end

    it "assigns account_params_key" do
      expect(instance.account_params_key).to eq(options[:account_params_key])
    end

    it "assigns current_user" do
      expect(instance.current_user).to eq(options[:current_user])
    end

    it "assigns facility" do
      expect(instance.facility).to eq(options[:facility])
    end

    it "assigns owner_user" do
      expect(instance.owner_user).to eq(options[:owner_user])
    end

    it "assigns params" do
      expect(instance.params).to eq(options[:params])
    end
  end

  describe ".for" do
    context "when passed nil" do
      it "returns default builder" do
        expect(described_class.for(nil)).to eq(AccountBuilder)
      end
    end

    context "when subclassed account builder exists" do
      before do
        ExistingBuilder = Class.new(AccountBuilder)
      end

      it "returns subclassed builder" do
        expect(described_class.for("Existing")).to eq(ExistingBuilder)
      end

      it "can find it by underscored name" do
        expect(described_class.for("existing")).to eq(ExistingBuilder)
      end
    end

    context "when the builder is namespaced" do
      before do
        module TestNamespace
          ExistingBuilder = Class.new(AccountBuilder)
        end
      end

      it "returns the builder" do
        expect(described_class.for("TestNamespace::Existing")).to eq(TestNamespace::ExistingBuilder)
      end
    end

    context "when subclassed account builder missing" do
      it "returns base builder" do
        expect(described_class.for("Foobar")).to eq(AccountBuilder)
      end
    end
  end

  describe "#build" do
    let(:builder) { described_class.new(options) }
    let(:options) do
      {
        account_type: "NufsAccount",
        current_user: build_stubbed(:user),
        facility: build_stubbed(:facility),
        owner_user: build_stubbed(:user),
        params: params,
      }
    end
    let(:params) { {} }

    it "returns an account" do
      expect(builder.build).to be_a(NufsAccount)
    end

    it "sets created_by" do
      expect(builder.build.created_by).to eq(options[:current_user].id)
    end

    it "skips setting updated_by" do
      expect(builder.build.updated_by).to be_nil
    end

    context "with params" do
      let(:params) do
        ActionController::Parameters.new(nufs_account: {
                                           account_number: "1234",
                                           description: "my description",
                                         })
      end

      it "sets account_number" do
        expect(builder.build.account_number).to eq(params[:nufs_account][:account_number])
      end

      it "sets description" do
        expect(builder.build.description).to eq(params[:nufs_account][:description])
      end
    end

    describe "account_users" do
      let(:owner_account_user) { builder.build.account_users.first }

      it "builds only one account_user" do
        expect(builder.build.account_users.size).to eq(1)
      end

      it "sets user to owner_user" do
        expect(owner_account_user.user_id).to eq(options[:owner_user].id)
      end

      it "sets user_role to Owner" do
        expect(owner_account_user.user_role).to eq("Owner")
      end

      it "sets created_by to current_user" do
        expect(owner_account_user.created_by).to eq(options[:current_user].id)
      end
    end

    context "when affilate supported" do
      let(:affiliate) { Affiliate.create!(name: "New Affiliate") }

      before do
        allow(NufsAccount).to receive(:using_affiliate?).and_return(true)
        allow(builder).to receive(:account_params_for_build).and_return([:affiliate_id])
      end

      context "and affiliate param blank" do
        it "skips setting affiliate" do
          expect(builder.build.affiliate_id).to be_nil
        end
      end

      context "and affiliate param present" do
        let(:params) do
          ActionController::Parameters.new(nufs_account: {
                                             affiliate_id: affiliate.id,
                                           })
        end

        it "sets affiliate" do
          expect(affiliate.id).to be_present
          expect(builder.build.affiliate_id).to eq(affiliate.id)
        end
      end
    end

    context "when affilate unsupported" do
      let(:affiliate) { Affiliate.create!(name: "New Affiliate") }

      before do
        allow(NufsAccount).to receive(:using_affiliate?).and_return(false)
      end

      context "and affiliate param blank" do
        it "skips setting affiliate" do
          expect(builder.build.affiliate_id).to be_nil
        end
      end

      context "and affiliate param present" do
        let(:params) do
          ActionController::Parameters.new(nufs_account: {
                                             affiliate_id: affiliate.id,
                                           })
        end

        it "does not set affiliate" do
          expect(builder.build.affiliate_id).to be_nil
        end
      end
    end
  end

  describe "#update" do
    let(:builder) { described_class.new(options) }
    let(:options) do
      {
        account: account,
        current_user: build_stubbed(:user),
        params: params,
      }
    end

    let(:account) do
      build_stubbed(:nufs_account,
                    account_number: "1234",
                    description: "foobar",
                   )
    end

    let(:params) do
      ActionController::Parameters.new(nufs_account: {
                                         description: "changed description",
                                       })
    end

    it "returns an account" do
      expect(builder.update).to be_a(NufsAccount)
    end

    it "sets updated_by" do
      expect(builder.update.updated_by).to eq(options[:current_user].id)
    end

    it "does not update account_number" do
      expect(builder.update.account_number).not_to eq(params[:nufs_account][:account_number])
    end

    it "updates description" do
      expect(builder.update.description).to eq(params[:nufs_account][:description])
    end
  end

end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountConfig, type: :model do

  let(:instance) { described_class.new }

  describe "#account_types" do
    it "supports concat" do
      instance.account_types << "FoobarAccount"
      expect(instance.account_types).to include("FoobarAccount")
    end
  end

  describe "#global_account_types" do
    it "returns difference of account_types and facility_account_types" do
      allow(instance).to receive(:account_types).and_return %w(FooAccount BarAccount)
      allow(instance).to receive(:facility_account_types).and_return ["FooAccount"]
      expect(instance.global_account_types).to contain_exactly("BarAccount")
    end
  end

  describe "#facility_account_types" do
    it "supports concat" do
      instance.facility_account_types << "FoobarAccount"
      expect(instance.facility_account_types).to include("FoobarAccount")
    end
  end

  describe "#statement_account_types" do
    it "supports concat" do
      instance.statement_account_types << "FoobarAccount"
      expect(instance.statement_account_types).to include("FoobarAccount")
    end
  end

  describe "#statement_account_types" do
    it "supports concat" do
      instance.statement_account_types << "FoobarAccount"
      expect(instance.statement_account_types).to include("FoobarAccount")
    end
  end

  describe "#account_type_to_param" do
    it "accepts a symbol" do
      expect(instance.account_type_to_param(:FooAccount)).to eq("foo_account")
    end

    it "accepts a namespaced class" do
      expect(instance.account_type_to_param("Foo::BarAccount")).to eq("foo_bar_account")
    end

    it "accepts an object" do
      expect(instance.account_type_to_param(TrueClass)).to eq("true_class")
    end
  end

  describe "#account_type_to_route" do
    it "accepts a normal class" do
      expect(instance.account_type_to_route("CreditCardAccount")).to eq("credit_cards")
    end

    it "accepts a namespaced class" do
      expect(instance.account_type_to_route("Foo::BarAccount")).to eq("foo_bars")
    end

    it "accepts an object" do
      expect(instance.account_type_to_route(TrueClass)).to eq("true_classes")
    end
  end

  describe "#multiple_account_types?" do
    context "when more than one account_types" do
      it "returns true" do
        allow(instance).to receive(:account_types).and_return(%w(FooAccount BarAccount))
        expect(instance.multiple_account_types?).to eq(true)
      end
    end

    context "when one or zero account_types" do
      it "returns false" do
        allow(instance).to receive(:account_types).and_return(["FooAccount"])
        expect(instance.multiple_account_types?).to eq(false)
      end
    end
  end

  describe "#statements_enabled?" do
    context "when statement_account_types are present" do
      it "returns true" do
        allow(instance).to receive(:statement_account_types).and_return(["FooAccount"])
        expect(instance.statements_enabled?).to eq(true)
      end
    end

    context "when statement_account_types is empty" do
      it "returns false" do
        allow(instance).to receive(:statement_account_types).and_return([])
        expect(instance.statements_enabled?).to eq(false)
      end
    end
  end

  describe "#affiliates_enabled?" do
    context "when affiliate_account_types are present" do
      it "returns true" do
        allow(instance).to receive(:affiliate_account_types).and_return(["FooAccount"])
        expect(instance.affiliates_enabled?).to eq(true)
      end
    end

    context "when affiliate_account_types is empty" do
      it "returns false" do
        allow(instance).to receive(:affiliate_account_types).and_return([])
        expect(instance.affiliates_enabled?).to eq(false)
      end
    end
  end

  describe "#per_facility?" do
    context "when account_type is included in facility_account_types" do
      it "returns true" do
        allow(instance).to receive(:facility_account_types).and_return(["FooAccount"])
        expect(instance.per_facility?("FooAccount")).to eq(true)
      end
    end
  end

  describe "#global?" do
    context "when account_type is included in global_account_types" do
      it "returns true" do
        allow(instance).to receive(:global_account_types).and_return(["FooAccount"])
        expect(instance.global?("FooAccount")).to eq(true)
      end
    end
  end

  describe "#using_affiliate?" do
    context "when account_type is included in affiliate_account_types" do
      it "returns true" do
        allow(instance).to receive(:affiliate_account_types).and_return(["FooAccount"])
        expect(instance.using_affiliate?("FooAccount")).to eq(true)
      end
    end
  end

end

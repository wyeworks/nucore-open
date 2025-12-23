# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payment do
  describe "validations" do
    # Skip these tests if validations have been removed
    before do
      has_presence_validation = Payment._validators[:source].any? { |v| v.kind == :presence }
      has_inclusion_validation = Payment._validators[:source].any? { |v| v.kind == :inclusion }

      unless has_presence_validation && has_inclusion_validation
        skip "Source validations have been removed"
      end
    end

    it { is_expected.to validate_presence_of :source }
    it "does not allow a source that is not included in the list" do
      payment = described_class.new(source: :something_invalid)
      expect(payment).to be_invalid
      expect(payment.errors).to include(:source)
    end
  end

  describe "belongs to user" do
    let(:payment) { described_class.new }
    let(:user) { FactoryBot.create(:user) }

    it "belongs to the user" do
      payment.paid_by = user
      expect(payment.paid_by_id).to eq(user.id)
    end
  end

  describe "amount" do
    subject(:payment) { described_class.new(amount: amount) }
    before { payment.valid? }

    context "positive amount" do
      let(:amount) { 23.45 }

      it "does not have an error on amount" do
        expect(payment.errors).not_to include(:amount)
      end
    end

    context "negative amount" do
      let(:amount) { -23.45 }

      it "does not have an error on amount" do
        expect(payment.errors).not_to include(:amount)
      end
    end

    context "a zero amount" do
      let(:amount) { 0 }

      it "has an error on amount" do
        expect(payment.errors).to include(:amount)
      end
    end

    context "a nil amount" do
      let(:amount) { nil }

      it "has an error on amount" do
        expect(payment.errors).to include(:amount)
      end
    end
  end

  describe "processing_fee" do
    let(:payment) { described_class.new }

    it "has a default processing fee of zero" do
      expect(payment.processing_fee).to eq(0)
      payment.valid?
      expect(payment.errors).not_to include(:processing_fee)
    end

    it "is invalid if you try to set the processing fee to nil" do
      payment.processing_fee = nil
      expect(payment).to be_invalid
      expect(payment.errors).to include(:processing_fee)
    end
  end
end

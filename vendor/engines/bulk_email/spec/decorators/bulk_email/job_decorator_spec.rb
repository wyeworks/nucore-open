# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkEmail::JobDecorator do
  subject(:job) { described_class.new(undecorated_job) }

  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:products) { FactoryBot.create_list(:setup_instrument, 2, facility: facility) }
  let(:product_id) { nil }
  let(:recipients) { %w(a@example.net b@example.com) }
  let(:selected_product_ids) { nil }
  let(:start_date) { "1/1/2015" }
  let(:end_date) { "12/31/2015" }
  let(:user_types) { %w(customers authorized_users account_owners) }

  let(:search_criteria) do
    {
      "bulk_email" => { "user_types" => user_types },
      "products" => selected_product_ids,
      "product_id" => product_id,
      "start_date" => start_date,
      "end_date" => end_date,
    }
  end

  let(:undecorated_job) do
    FactoryBot.build_stubbed(:bulk_email_job,
                             recipients: recipients,
                             search_criteria: search_criteria)
  end

  describe "#sender" do
    it { expect(job.sender).to eq(job.user.email) }
  end

  describe "#recipient_list" do
    it { expect(job.recipient_list).to eq("a@example.net, b@example.com") }
  end

  describe "#products" do
    context "when a product list is set" do
      let(:selected_product_ids) { products.map(&:id).map(&:to_s) }

      context "when a primary product is set" do
        let(:product_id) { products.first.id }
        it { expect(job.products).to eq(products.map(&:name).join(", ")) }
      end

      context "when a primary product is not set" do
        it { expect(job.products).to eq(products.map(&:name).join(", ")) }
      end
    end

    context "when a product list is not set" do
      context "when a primary product is set" do
        let(:product_id) { products.first.id }
        it { expect(job.products).to eq products.first.name }
      end

      context "when a primary product is not set" do
        it { expect(job.products).to be_blank }
      end
    end
  end

  describe "#user_types" do
    it { expect(job.user_types).to eq("Customers, Authorized Users, Account Owners") }
  end

  describe "#start_date" do
    context "when stored in US format" do
      it { expect(job.start_date).to eq "01/01/2015" }
    end

    context "when stored in ISO format" do
      let(:start_date) { "2015-01-01" }
      it { expect(job.start_date).to eq "01/01/2015" }
    end

    context "when unset" do
      let(:start_date) { nil }
      it { expect(job.start_date).to eq "not set" }
    end
  end

  describe "#end_date" do
    context "when stored in US format" do
      it { expect(job.end_date).to eq "12/31/2015" }
    end

    context "when stored in ISO format" do
      let(:end_date) { "2015-12-31" }
      it { expect(job.end_date).to eq "12/31/2015" }
    end

    context "when unset" do
      let(:end_date) { nil }
      it { expect(job.end_date).to eq "not set" }
    end
  end
end

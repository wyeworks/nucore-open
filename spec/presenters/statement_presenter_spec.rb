# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementPresenter do
  subject { StatementPresenter.new(statement) }
  let(:account) { statement.account }
  let(:created_at) { Time.zone.local(2015, 10, 14, 17, 41) }
  let(:creator) { create(:user) }
  let(:facility) { statement.facility }
  let(:statement) { create(:statement, created_at: created_at, created_by: creator.id) }
  let(:user1) { create(:user, :administrator) }
  let(:user2) { create(:user, :administrator) }

  describe ".wrap" do
    let(:statements) { build_stubbed_list(:statement, 5) }

    it "converts an enumerable collection into presenter objects" do
      expect(described_class.wrap(statements)).to all(be_a(described_class))
    end
  end

  describe "#download_path" do
    it "returns a download path to the PDF version of the statement" do
      if Account.config.statements_enabled?
        expect(subject.download_path)
          .to eq("/#{facilities_route}/#{facility.url_name}/accounts/#{account.id}/statements/#{statement.id}.pdf")
      end
    end
  end

  describe "#order_count" do
    before(:each) do
      allow(subject).to receive(:order_details).and_return(order_details)
    end

    let(:order_details) { build_stubbed_list(:order_detail, 5) }

    it "returns the number of order details" do
      expect(subject.order_count).to eq(5)
    end
  end

  describe "#sent_at" do
    it "returns the statement's formatted creation time" do
      expect(subject.sent_at).to eq("10/14/2015 5:41 PM")
    end
  end

  describe "#sent_by" do
    context "when the statement's creator exists" do
      it "returns the creator's full name" do
        expect(subject.sent_by).to eq(creator.full_name)
      end
    end

    context "when the statement's creator does not exist" do
      before { statement.created_by = nil }

      it "returns 'Unknown'" do
        expect(subject.sent_by).to eq("Unknown")
      end
    end
  end

  context "with closed events" do
    let!(:log_event1) { LogEvent.log(statement, :closed, user1) }
    let!(:log_event2) { LogEvent.log(statement, :closed, user2) }

    describe "#closed_by_user_full_names" do
      it "lists user full names" do
        expect(subject.closed_by_user_full_names).to eq "#{user1.full_name}\n#{user2.full_name}"
      end
    end

    describe "#closed_by_times" do
      it "lists close times" do
        time_string = "#{SpecDateHelper.format_usa_datetime(log_event1.event_time)}\n#{SpecDateHelper.format_usa_datetime(log_event2.event_time)}"

        expect(subject.closed_by_times).to eq time_string
      end
    end
  end
end

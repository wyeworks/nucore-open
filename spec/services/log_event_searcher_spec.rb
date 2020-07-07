require "rails_helper"

RSpec.describe LogEventSearcher do

  describe "filtering by dates" do
    let!(:log_1) { create(:log_event, event_time: 1.month.ago) }
    let!(:log_2) { create(:log_event, event_time: 1.week.ago) }
    let!(:log_3) { create(:log_event, event_time: 1.day.ago) }

    it "finds all the items without a date filter" do
      expect(LogEvent.search).to match_array([log_1, log_2, log_3])
    end

    it "works with a date filter" do
      expect(LogEvent.search(start_date: 2.weeks.ago, end_date: 2.days.ago))
        .to match_array([log_2])
    end

    it "works with a flipped date filter" do
      expect(LogEvent.search(start_date: 2.days.ago, end_date: 2.weeks.ago))
        .to match_array([log_2])
    end

    it "works without a start_date" do
      expect(LogEvent.search(end_date: 2.days.ago))
        .to match_array([log_1, log_2])
    end

    it "works without an end date" do
      expect(LogEvent.search(start_date: 2.weeks.ago))
        .to match_array([log_2, log_3])
    end
  end

  describe "filtering by events" do
    let(:account) { create(:account, :with_account_owner) }
    let(:user) { account.owner_user }
    let(:account_user) { account.owner }
    let!(:log_1) { create(:log_event, loggable: account, event_type: :create) }
    let!(:log_2) { create(:log_event, loggable: account_user, event_type: :create) }
    let!(:log_3) { create(:log_event, loggable: user, event_type: :create) }

    it "whitelists event type" do
      search = LogEventSearcher.new(events: ["user.create", "cheeseburger.create", "user.update"])
      expect(search.events).to contain_exactly("user.create")
    end

    it "filters on event type" do
      expect(LogEvent.search(events: ["account.create"])).to match_array([log_1])
      expect(LogEvent.search(events: ["account_user.create"])).to match_array([log_2])
      expect(LogEvent.search(events: ["user.create"])).to match_array([log_3])
      expect(LogEvent.search(events: ["user.create", "account_user.create"]))
        .to match_array([log_2, log_3])
    end
  end

  describe "finding accounts" do
    let(:account) { create(:account, :with_account_owner, account_number: "12345-12345") }
    let!(:log_event) { create(:log_event, loggable: account, event_type: :create) }

    it "finds the account" do
      results = described_class.new(query: "12345-12345").search
      expect(results).to include(log_event)
    end

    it "does not find it if it is not a match" do
      results = described_class.new(query: "54321").search
      expect(results).not_to include(log_event)
    end
  end

  describe "finding users" do
    let(:user) { create(:user, username: "myuser") }
    let!(:log_event) { create(:log_event, loggable: user, event_type: :create) }

    it "finds the user" do
      results = described_class.new(query: "myuser").search
      expect(results).to include(log_event)
    end

    it "does not find the user if it is not a match" do
      results = described_class.new(query: "random").search
      expect(results).not_to include(log_event)
    end
  end

  describe "finding journal" do
    let(:journal) { create(:journal) }
    let!(:log_event) { create(:log_event, loggable: journal, event_type: :create) }

    it "finds the journal" do
      results = described_class.new(query: journal.id.to_s).search
      expect(results).to include(log_event)
    end

    it "does not find it if it is not a match" do
      results = described_class.new(query: "54321").search
      expect(results).not_to include(log_event)
    end
  end

  describe "finding statement" do
    let(:account) { create(:account, :with_account_owner, account_number: "12345") }
    let(:facility) { create(:setup_facility) }
    let(:statement) { create(:statement, facility: facility, account: account)}
    let!(:log_event) { create(:log_event, loggable: statement, event_type: :create) }

    it "finds the statement" do
      results = described_class.new(query: statement.invoice_number).search
      expect(results).to include(log_event)
    end

    it "does not find it if it is not a match" do
      results = described_class.new(query: "54321").search
      expect(results).not_to include(log_event)
    end
  end

  describe "finds account user memberships" do
    let(:user) { create(:user, username: "myuser") }
    let(:account) { create(:account, :with_account_owner, account_number: "12345-12345") }
    let(:account_user) { create(:account_user, :purchaser, user: user, account: account) }
    let!(:log_event) { create(:log_event, loggable: account_user, event_type: :create) }

    it "finds it by the user" do
      results = described_class.new(query: "myuser").search
      expect(results).to include(log_event)
    end

    it "finds it by the account" do
      results = described_class.new(query: "12345-12345").search
      expect(results).to include(log_event)
    end

    it "does not find it if no match" do
      results = described_class.new(query: "random").search
      expect(results).not_to include(log_event)
    end
  end

  describe "finds user roles" do
    let(:user) { create(:user, username: "myuser") }
    let(:facility) { create(:facility, name: "My Facility") }

    describe "facility role" do
      let!(:user_role) { create(:user_role, :facility_staff, user: user, facility: facility) }
      let!(:log_event) { create(:log_event, loggable: user_role, event_type: :create) }

      it "finds by the user" do
        results = described_class.new(query: "myuser").search
        expect(results).to include(log_event)
      end

      it "finds the user even if the role was since deleted" do
        user_role.destroy
        results = described_class.new(query: "myuser").search
        expect(results).to include(log_event)
      end

      it "finds by the facility" do
        results = described_class.new(query: "my facility").search
        expect(results).to include(log_event)
      end
    end
  end

  describe "finding order details" do
    let!(:user) { FactoryBot.create(:user) }
    let(:order) { create(:order, created_by_user: user, user: user) }
    let(:product) { create(:setup_item) }
    let(:order_detail) { create(:order_detail, order: order, product: product) }
    let!(:log_event) { create(:log_event, loggable: order_detail, event_type: :resolve) }
    
    it "finds the order detail" do
      results = described_class.new(query: "#{order.id}-#{order_detail.id}").search
      expect(results).to include(log_event)
    end

    it "does not find it if it is not a match" do
      results = described_class.new(query: "54321").search
      expect(results).not_to include(log_event)
    end
  end

  describe "finding product user" do
    let(:user) { create(:user) }
    let(:item) { FactoryBot.create(:setup_item) }
    let(:product_user) { ProductUser.create(product: item, user: user, approved_by: user.id) }
    let!(:log_event) { create(:log_event, loggable: product_user, event_type: :create) }

    it "finds the product user" do
      results = described_class.new(query: "#{item.name}").search
      expect(results).to include(log_event)
    end

    it "does not find it if it is not a match" do
      results = described_class.new(query: "54321").search
      expect(results).not_to include(log_event)
    end
  end
end

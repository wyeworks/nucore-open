require "rails_helper"

RSpec.describe LogEventSearcher do
  def search(*, **)
    LogEventSearcher.new(*, **).search
  end

  describe "filtering by dates" do
    let!(:log_1) { create(:log_event, event_time: 1.month.ago) }
    let!(:log_2) { create(:log_event, event_time: 1.week.ago) }
    let!(:log_3) { create(:log_event, event_time: 1.day.ago) }

    it "finds all the items without a date filter" do
      expect(search).to match_array([log_1, log_2, log_3])
    end

    it "works with a date filter" do
      expect(search(start_date: 2.weeks.ago, end_date: 2.days.ago))
        .to match_array([log_2])
    end

    it "works with a flipped date filter" do
      expect(search(start_date: 2.days.ago, end_date: 2.weeks.ago))
        .to match_array([log_2])
    end

    it "works without a start_date" do
      expect(search(end_date: 2.days.ago))
        .to match_array([log_1, log_2])
    end

    it "works without an end date" do
      expect(search(start_date: 2.weeks.ago))
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

    it "filters on event type" do
      expect(
        search(events: ["account.create"])
      ).to match_array([log_1])
      expect(
        search(events: ["account_user.create"])
      ).to match_array([log_2])
      expect(
        search(events: ["user.create"])
      ).to match_array([log_3])
      expect(
        search(events: ["user.create", "account_user.create"])
      ).to match_array([log_2, log_3])
    end
  end

  describe "filtering by invoice number" do
    include_context "billing statements"
    let!(:log_1) { create(:log_event, loggable: statement1, event_type: :create) }
    let!(:log_2) { create(:log_event, loggable: statement2, event_type: :create) }

    it "finds the statement by full invoice number" do
      results = search(invoice_number: statement1.invoice_number)
      expect(results).to match_array([log_1])
    end

    it "finds the statement by statement ID" do
      results = search(invoice_number: statement1.id.to_s)
      expect(results).to match_array([log_1])
    end

    it "finds statements by partial match of invoice number" do
      # Extract part of the invoice number (e.g., if invoice is "1-23", search for "1-2")
      partial_invoice = statement1.invoice_number[0..-2]
      results = search(invoice_number: partial_invoice)
      expect(results).to match_array([log_1])
    end

    it "finds statements by partial match of statement ID" do
      # Use last digit of statement ID
      partial_id = statement1.id.to_s[-1]
      results = search(invoice_number: partial_id)
      expect(results.map(&:loggable_id)).to include(statement1.id)
    end

    it "finds nothing when invoice number doesn't match" do
      results = search(invoice_number: "99999")
      expect(results).to be_empty
    end
  end

  describe "filtering by payment source" do
    include_context "billing statements with deposit numbers"

    let!(:log_1) { create(:log_event, loggable: statement1, event_type: :create) }
    let!(:log_2) { create(:log_event, loggable: statement2, event_type: :create) }

    it "finds statements by account number" do
      results = search(payment_source: "CHECK")
      expect(results).to match_array([log_1])
    end

    it "finds statements by partial match in account number" do
      results = search(payment_source: "WIRE")
      expect(results).to match_array([log_2])
    end

    it "finds statements by account description" do
      results = search(payment_source: "Research Lab")
      expect(results).to match_array([log_1])
    end

    it "finds statements by partial match in description" do
      results = search(payment_source: "Chemistry")
      expect(results).to match_array([log_2])
    end

    it "finds nothing when payment source doesn't match" do
      results = search(payment_source: "bitcoin")
      expect(results).to be_empty
    end
  end

  describe "finding accounts" do
    let(:account) { create(:account, :with_account_owner, account_number: "12345-12345") }
    let!(:log_event) { create(:log_event, loggable: account, event_type: :create) }

    it "finds the account" do
      results = search(query: "12345-12345")
      expect(results).to include(log_event)
    end

    it "does not find it if it is not a match" do
      results = search(query: "54321")
      expect(results).not_to include(log_event)
    end
  end

  describe "finding users" do
    let(:user) { create(:user, username: "myuser") }
    let!(:log_event) { create(:log_event, loggable: user, event_type: :create) }

    it "finds the user" do
      results = search(query: "myuser")
      expect(results).to include(log_event)
    end

    it "does not find the user if it is not a match" do
      results = search(query: "random")
      expect(results).not_to include(log_event)
    end
  end

  describe "finding journal" do
    let(:journal) { create(:journal) }
    let!(:log_event) { create(:log_event, loggable: journal, event_type: :create) }

    it "finds the journal" do
      results = search(query: journal.id.to_s)
      expect(results).to include(log_event)
    end

    it "does not find it if it is not a match" do
      results = search(query: "54321")
      expect(results).not_to include(log_event)
    end
  end

  describe "finding statement" do
    let(:account) { create(:account, :with_account_owner, account_number: "12345") }
    let(:facility) { create(:setup_facility) }
    let(:statement) { create(:statement, facility:, account:)}
    let!(:log_event) { create(:log_event, loggable: statement, event_type: :create) }

    it "finds the statement" do
      results = search(query: statement.invoice_number)
      expect(results).to include(log_event)
    end

    it "does not find it if it is not a match" do
      results = search(query: "54321")
      expect(results).not_to include(log_event)
    end
  end

  describe "finds account user memberships" do
    let(:user) { create(:user, username: "myuser") }
    let(:account) { create(:account, :with_account_owner, account_number: "12345-12345") }
    let(:account_user) { create(:account_user, :purchaser, user:, account:) }
    let!(:log_event) { create(:log_event, loggable: account_user, event_type: :create) }

    it "finds it by the user" do
      results = search(query: "myuser")
      expect(results).to include(log_event)
    end

    it "finds it by the account" do
      results = search(query: "12345-12345")
      expect(results).to include(log_event)
    end

    it "does not find it if no match" do
      results = search(query: "random")
      expect(results).not_to include(log_event)
    end
  end

  describe "finds user roles" do
    let(:user) { create(:user, username: "myuser") }
    let(:facility) { create(:facility, name: "My Facility") }

    describe "facility role" do
      let!(:user_role) { create(:user_role, :facility_staff, user:, facility:) }
      let!(:log_event) { create(:log_event, loggable: user_role, event_type: :create) }

      it "finds by the user" do
        results = search(query: "myuser")
        expect(results).to include(log_event)
      end

      it "finds the user even if the role was since deleted" do
        user_role.destroy
        results = search(query: "myuser")
        expect(results).to include(log_event)
      end

      it "finds by the facility" do
        results = search(query: "my facility")
        expect(results).to include(log_event)
      end
    end
  end

  describe "finding order details" do
    let!(:user) { FactoryBot.create(:user) }
    let(:order) { create(:order, created_by_user: user, user:) }
    let(:product) { create(:setup_item) }
    let(:order_detail) { create(:order_detail, order:, product:) }
    let!(:log_event) { create(:log_event, loggable: order_detail, event_type: :resolve) }

    it "finds the order detail" do
      results = search(query: "#{order.id}-#{order_detail.id}")
      expect(results).to include(log_event)
    end

    it "does not find it if it is not a match" do
      results = search(query: "54321")
      expect(results).not_to include(log_event)
    end
  end

  describe "finding product user" do
    let(:user) { create(:user) }
    let(:item) { FactoryBot.create(:setup_item) }
    let(:product_user) { ProductUser.create(product: item, user:, approved_by: user.id) }
    let!(:log_event) { create(:log_event, loggable: product_user, event_type: :create) }

    it "finds the product user" do
      results = search(query: "#{item.name}")
      expect(results).to include(log_event)
    end

    it "does not find it if it is not a match" do
      results = search(query: "54321")
      expect(results).not_to include(log_event)
    end
  end

  describe "can specify a relation" do
    let(:relation) { LogEvent.where(event_type: "some_type") }
    let(:user) { create(:user) }
    let(:event_1) do
      LogEvent.create(event_type: "some_type", loggable: create(:user))
    end
    let(:event_2) do
      LogEvent.create(
        event_type: "other_type",
        loggable: create(:user, first_name: "Cactus"),
      )
    end

    it "search returns the specified relation" do
      results = search(relation:)
      expect(results).to match([event_1])
    end

    it "filters over the specified relation" do
      results = search(query: "Cactus", relation:)
      expect(results).to be_empty
    end
  end
end

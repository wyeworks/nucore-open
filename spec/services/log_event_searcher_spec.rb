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
    let(:account_1) { create(:account, :with_account_owner) }
    let(:account_2) { create(:account, :with_account_owner) }
    let(:facility) { create(:setup_facility) }
    let(:statement_1) { create(:statement, account: account_1, facility: facility) }
    let(:statement_2) { create(:statement, account: account_2, facility: facility) }
    let!(:log_1) { create(:log_event, loggable: statement_1, event_type: :create) }
    let!(:log_2) { create(:log_event, loggable: statement_2, event_type: :create) }

    it "finds the statement by invoice number" do
      results = search(invoice_number: statement_1.invoice_number)
      expect(results).to match_array([log_1])
    end

    it "finds nothing when invoice number doesn't match" do
      results = search(invoice_number: "99999")
      expect(results).to be_empty
    end
  end

  describe "filtering by payment source" do
    let(:account_1) { create(:account, :with_account_owner) }
    let(:account_2) { create(:account, :with_account_owner) }
    let(:facility) { create(:setup_facility) }
    let(:user) { create(:user) }
    let(:statement_1) { create(:statement, account: account_1, facility: facility) }
    let(:statement_2) { create(:statement, account: account_2, facility: facility) }
    let!(:payment_1) { create(:payment, statement: statement_1, account: account_1, source: "check", amount: 100.0, processing_fee: 0.0, paid_by: user) }
    let!(:payment_2) { create(:payment, statement: statement_2, account: account_2, source: "check", amount: 200.0, processing_fee: 0.0, paid_by: user) }
    let!(:log_1) { create(:log_event, loggable: statement_1, event_type: :create) }
    let!(:log_2) { create(:log_event, loggable: statement_2, event_type: :create) }

    before do
      # Add creditcard as a valid payment source for these tests
      Payment.valid_sources << :creditcard unless Payment.valid_sources.include?(:creditcard)
      payment_2.update!(source: "creditcard")
    end

    after do
      # Clean up the added source
      Payment.valid_sources.delete(:creditcard)
    end

    it "finds statements by payment source" do
      results = search(payment_source: "check")
      expect(results).to match_array([log_1])
    end

    it "works with partial matches" do
      results = search(payment_source: "credit")
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
    let(:statement) { create(:statement, facility: facility, account: account)}
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
    let(:account_user) { create(:account_user, :purchaser, user: user, account: account) }
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
      let!(:user_role) { create(:user_role, :facility_staff, user: user, facility: facility) }
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
    let(:order) { create(:order, created_by_user: user, user: user) }
    let(:product) { create(:setup_item) }
    let(:order_detail) { create(:order_detail, order: order, product: product) }
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
    let(:product_user) { ProductUser.create(product: item, user: user, approved_by: user.id) }
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

require "rails_helper"

RSpec.describe JournalRow do

  describe "validations" do
    it { is_expected.to validate_presence_of(:journal_id) }
    it { is_expected.to validate_presence_of(:amount) }

    describe "with expense_accounts on", feature_setting: { expense_accounts: true } do
      it { is_expected.to validate_presence_of(:account) }
    end

    describe "with expense_accounts on", feature_setting: { expense_accounts: false } do
      it { is_expected.not_to validate_presence_of(:account) }
    end
  end

  describe "fulfilled_at" do
    it "defaults to nil" do
      journal_row = described_class.new
      expect(journal_row.fulfilled_at).to be_blank
    end

    it "delegates to the order detail do" do
      one_day_ago = 1.day.ago
      order_detail = OrderDetail.new(fulfilled_at: one_day_ago)
      journal_row = described_class.new(order_detail: order_detail)
      expect(journal_row.fulfilled_at).to eq(one_day_ago)
    end
  end

end

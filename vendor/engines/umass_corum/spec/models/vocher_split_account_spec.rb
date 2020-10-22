# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::VoucherSplitAccount do
  it "only creates one VoucherAccount" do
    3.times { FactoryBot.create(:voucher_split_account) }
    travel_to_and_return(1.week.from_now) { FactoryBot.create(:voucher_split_account) }
    expect(UmassCorum::VoucherSplitAccount.count).to eq 4
    expect(UmassCorum::VoucherAccount.count).to eq 1
  end
end

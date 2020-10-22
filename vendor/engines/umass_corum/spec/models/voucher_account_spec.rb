# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::VoucherAccount do
  let(:account) { described_class.new }

  it "doesn't require an owner" do
    expect(account.missing_owner?).to be_falsey
  end

  it "has a fake owner_user" do
    expect(account.owner_user).to be_a(User)
    expect(account.owner_user.username).to eq "MIVP"
  end

  it "sets an expiration date on create" do
    expect(account.expires_at).to be_nil
    account.save
    expect(account.expires_at).to eq(25.years.from_now)
  end

  it "only creates one instance" do
    expect do
      UmassCorum::VoucherAccount.instance
      UmassCorum::VoucherAccount.instance
      travel_to_and_return(1.week.from_now) { UmassCorum::VoucherAccount.instance }
    end.to change(UmassCorum::VoucherAccount, :count).by(1)
  end
end

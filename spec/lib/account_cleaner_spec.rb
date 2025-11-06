# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountCleaner do

  before :each do
    @account                  = FactoryBot.create(:setup_account, expires_at: Time.zone.parse("2063-04-20 14:30:30"))
    @end_of_day_account       = FactoryBot.create(:setup_account, expires_at: Time.zone.parse("2063-04-21 23:59:59"))
    @beginning_of_day_account = FactoryBot.create(:setup_account, expires_at: Time.zone.parse("2063-04-22 00:00:00"))
  end

  context "update accounts.expires_at" do

    it "should not update if expires_at has a time other than beginning of day or end of day" do
      expect(AccountCleaner.clean_expires_at(@account)).to be_falsey
    end

    it "should not update if expires_at is set to end of day" do
      expect(AccountCleaner.clean_expires_at(@end_of_day_account)).to be_falsey
    end

    it "should update if expires_at is set to beginning of day" do
      expect(AccountCleaner.clean_expires_at(@beginning_of_day_account)).to be true
    end

  end

end

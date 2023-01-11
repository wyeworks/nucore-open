# frozen_string_literal: true

# These shared examples require a `let(:account)`

RSpec.shared_examples_for "AffiliateAccount" do
  let(:affiliate) { FactoryBot.create(:affiliate) }

  context "with the :po_require_affiliate_account flag set to true", feature_setting: { po_require_affiliate_account: true } do
    it { is_expected.to validate_presence_of(:affiliate_id) }

    it "requires affiliate_other if affiliate is 'Other'" do
      account.affiliate = Affiliate.OTHER
      account.affiliate_other = nil
      expect(account).to be_invalid
      expect(account)
        .to validate_length_of(:affiliate_other).is_at_least(1)
    end

    it "does not require affiliate_other if affiliate is not 'Other'" do
      account.affiliate = affiliate
      account.affiliate_other = nil
      expect(account.affiliate).to be_present
      expect(account.affiliate).not_to be_other
      account.valid?
      expect(account)
        .not_to validate_length_of(:affiliate_other).is_at_least(1)
    end
  end

  context "with the :po_require_affiliate_account flag set to false", feature_setting: { po_require_affiliate_account: false } do
    it { is_expected.not_to validate_presence_of(:affiliate_id) if account.is_a? PurchaseOrderAccount }

    it "requires affiliate_other if affiliate is 'Other'" do
      account.affiliate = Affiliate.OTHER
      account.affiliate_other = nil
      expect(account).to be_invalid
      expect(account)
        .to validate_length_of(:affiliate_other).is_at_least(1)
    end

    it "does not require affiliate_other if affiliate is not 'Other'" do
      account.affiliate = affiliate
      account.affiliate_other = nil
      expect(account.affiliate).to be_present
      expect(account.affiliate).not_to be_other
      account.valid?
      expect(account)
        .not_to validate_length_of(:affiliate_other).is_at_least(1)
    end
  end
end

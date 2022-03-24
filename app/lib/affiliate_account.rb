# frozen_string_literal: true

# Should be included by any +Account+ that requires an +Affiliate+
module AffiliateAccount

  def self.included(base)
    base.validates_presence_of :affiliate_id
    base.validates_length_of :affiliate_other,
                             minimum: 1,
                             if: proc { |cc| cc.affiliate.try(:subaffiliates_enabled?) }
  end

end

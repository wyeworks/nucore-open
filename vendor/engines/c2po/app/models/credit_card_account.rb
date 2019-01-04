# frozen_string_literal: true

class CreditCardAccount < Account

  include AffiliateAccount
  include ReconcilableAccount

  attr_readonly :account_number
  before_validation :setup_false_credit_card_number

  validates_presence_of :name_on_card
  validates_numericality_of :expiration_month, only_integer: true, greater_than: 0, less_than: 13
  validate :expiration_year_in_future

  def expiration_year_in_future
    if expiration_year.nil? || expiration_year < Time.zone.now.year || expiration_year > Time.zone.now.year + 20
      errors.add(:expiration_year, "must be between #{Time.zone.now.year} and #{Time.zone.now.year + 20}")
    end
  end

  def formatted_expires_at
    expires_at.try(:strftime, "%m/%Y")
  end

  protected

  def setup_false_credit_card_number
    self.account_number = "xxxx-xxxx-xxxx-xxxx"
  end

end

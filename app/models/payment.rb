class Payment < ActiveRecord::Base
  belongs_to :account, inverse_of: :payments
  belongs_to :statement, inverse_of: :payments

  # Add additional sources in an engine with Payment.valid_sources << :new_source
  def self.valid_sources
    @@valid_sources ||= [:check]
  end

  validate :source, presence: true, inclusion: { in: valid_sources }
  validate :account, :amount, presence: true

end

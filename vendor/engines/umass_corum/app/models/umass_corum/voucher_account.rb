# frozen_string_literal: true

module UmassCorum

  # An account to track expenses against the Mass Innovation Voucher Program (MIVP).
  # MIVP provides mini-grants to external users, covering 50% or 75% of fees.
  # Customers receive a credit on their invoice for the MIVP portion of the cost.
  # At the end of each fiscal quarter, the expenses charged against the VoucherAccount
  # are submitted to MIVP for reimbursement. MIVP funds are then allocated to
  # individual cores, closing out any open/partially paid orders.
  class VoucherAccount < Account

    before_validation :set_expires_at, on: :create

    def self.instance
      # setting created_by to 0 to pass validations
      # there should only be one VoucherAccount instance
      find_or_create_by(account_number: "MIVP", description: "MIVP Voucher Account", created_by: 0)
    end

    def missing_owner?
      false
    end

    def set_expires_at
      self.expires_at ||= 25.years.from_now
    end

    def owner_user
      User.new(username: "MIVP", first_name: "MIVP", last_name: "MIVP", email: "MIVP")
    end

  end

end

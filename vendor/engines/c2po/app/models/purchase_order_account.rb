# frozen_string_literal: true

class PurchaseOrderAccount < Account

  include AffiliateAccount
  include ReconcilableAccount

  validates_presence_of :account_number

  def to_s(with_owner = false, flag_suspended = true, with_facility: true)
    desc = super(with_owner, false)
    desc += " / #{facility_description}" if with_facility && facilities.present?
    desc += " (#{display_status.upcase})" if flag_suspended && suspended?
    desc
  end

  private

  def facility_description
    if facilities.length > 1
      I18n.t(
        "purchase_order_account.shared_facility_description",
        count: facilities.length,
        facilities: Facility.model_name.human(count: facilities.length)
      )
    else
      facilities.first.name
    end
  end

end

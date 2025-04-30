# frozen_string_literal: true

class BillingLogEventsController < GlobalSettingsController
  include ListBillingLogEvents

  def admin_tab?
    true
  end

end

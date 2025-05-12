# frozen_string_literal: true

module AccountsHelper

  def account_input(form)
    form.input :account_id,
      as: :select,
      label: OrderDetail.human_attribute_name(:account),
      collection: available_accounts_array,
      selected: @order_detail.account_id,
      include_blank: false,
      disabled: edit_disabled?
  end

  def payment_source_link_or_text(account)
    if current_ability.can?(:edit, account)
      link_to account, facility_account_path(current_facility, account)
    else
      account.to_s
    end
  end

  def split_account_link_or_text(account)
    acct_desc = account.to_s(with_facility: false)
    if current_ability.can?(:edit, account)
      link_to acct_desc, facility_account_path(current_facility, account)
    else
      acct_desc
    end
  end

  def show_account_facilities_tab?(ability, account)
    SettingsHelper.feature_on?(:multi_facility_accounts) && account.per_facility? && ability.can?(:edit, AccountFacilityJoinsForm.new(account: account))
  end

  private

  def available_accounts_array
    @available_accounts.map do |account|
      [
        account.to_s,
        account.id,
        { "data-account-owner" => account.owner_user_name },
      ]
    end
  end

  def account_expiration(expires_at)
    hide_future_expiration = SettingsHelper.feature_on?(:hide_account_far_future_expiration)

    if hide_future_expiration && expires_at > 75.years.from_now
      "—"
    else
      human_date(expires_at)
    end
  end

end

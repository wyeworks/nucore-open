# frozen_string_literal: true

module AccountsHelper

  def toggle_expired_account_btn
    toggle_params = request.query_parameters.dup.except(:page)

    if params[:account_status].blank?
      # `all` is only used to override the default account_status filter.
      # It does not really filter anything
      toggle_params[:account_status] = "all"
      label = t("views.facility_accounts.account_table.show_text")
    else
      toggle_params.delete :account_status
      label = t("views.facility_accounts.account_table.hide_text")
    end

    link_to(
      label,
      facility_accounts_path(current_facility, toggle_params),
      class: "btn btn-primary",
    )
  end

  def account_input(form, disabled: false)
    form.input :account_id,
      as: :select,
      label: OrderDetail.human_attribute_name(:account),
      collection: available_accounts_array,
      selected: @order_detail.account_id,
      include_blank: false,
      disabled: edit_disabled? || disabled
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
    SettingsHelper.feature_on?("accounts.multi_facility_accounts") && account.per_facility? && ability.can?(:edit, AccountFacilityJoinsForm.new(account: account))
  end

  def use_custom_reconciliation_features?(account_class = nil)
    return false if account_class.blank?

    Account.config.using_custom_reconciliation?(account_class.name)
  end

  def account_price_groups_select_options
    if current_facility.cross_facility?
      PriceGroup.includes(:facility).all.map(&:presenter).map do |price_group|
        [price_group.long_name, price_group.id]
      end
    else
      PriceGroup.for_facility(current_facility).map do |price_group|
        [price_group.name, price_group.id]
      end
    end
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
    hide_future_expiration = SettingsHelper.feature_on?("accounts.hide_account_far_future_expiration")

    if hide_future_expiration && expires_at > 75.years.from_now
      "—"
    else
      human_date(expires_at)
    end
  end

end

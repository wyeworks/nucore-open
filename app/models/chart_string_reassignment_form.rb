# frozen_string_literal: true

class ChartStringReassignmentForm

  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_reader :account_id, :available_accounts, :order_details

  def initialize(order_details, user = nil)
    @order_details = order_details
    @user = user
    @available_accounts = available_accounts
  end

  def available_accounts
    accounts = @user.present? ? Account.administered_by(@user).to_a : @order_details.map(&:available_accounts)
    accounts.flatten.uniq.sort_by(&:description)
  end

  def persisted?
    false
  end

  def facility
    @facility ||= @order_details.first.facility
  end

end

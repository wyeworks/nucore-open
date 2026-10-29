# frozen_string_literal: true

class AccountProductErrorsFinder

  def initialize(accounts, products, user)
    @accounts = accounts
    @products = products
    @user = user
  end

  def errors
    @accounts.each_with_object({}) do |account, account_errors|
      error = first_error_for(account)
      account_errors[account.id] = error if error
    end
  end

  private

  def first_error_for(account)
    @products.each do |product|
      error = account.validate_against_product(product, @user)
      return error if error
    end

    nil
  end

end

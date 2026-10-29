# frozen_string_literal: true

module SecureRooms
  class AccountPresenter
    include ActiveModel::Serializers::JSON

    attr_reader :account

    def self.wrap(accounts)
      Array(accounts).map { |account| new(account) }
    end

    def initialize(account)
      @account = account
    end

    private

    delegate :id, :type, :description, :account_number, :expiration_month, :expiration_year, to: :account

    def attribute_names
      %w(id type description account_number expiration_month expiration_year owner_name)
    end

    def attributes
      @attributes ||= attribute_names.map { |attr| [attr, nil] }.to_h
    end

    def owner_name
      account.owner_user_name
    end
  end
end

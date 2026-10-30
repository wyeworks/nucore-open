# frozen_string_literal: true

class FacilityAccountValidator
  attr_reader :facility, :account

  def initialize(facility, account)
    @facility = facility
    @account = account
  end

  def valid?
    raise NotImplementedError
  end
end

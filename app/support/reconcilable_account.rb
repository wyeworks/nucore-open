# frozen_string_literal: true

module ReconcilableAccount

  # This is used as a class method on account classes that extend this module.
  # Reconcilable statement accounts are collected by AccountConfig
  def reconcilable?
    true
  end

end

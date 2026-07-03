# frozen_string_literal: true

# CanCanCan 3.4+ makes rules defined on an STI subclass also match class-level
# `can?` checks against the parent. If a rule targets an STI child (say OfflineReservation),
# that rule now also matches when the check subject is the STI parent class (Reservation).
StiDetector.singleton_class.prepend(Module.new do
  def sti_class?(_subject)
    false
  end
end)

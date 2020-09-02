# frozen_string_literal: true

class AdminReservationExpirer

  def expire!
    expired_reservations.destroy_all
  end

  private

  def expired_reservations
    if Nucore::Database.oracle?
      AdminReservation.where("reserve_start_at - expires_mins_before / (60*24) < TO_TIMESTAMP(?)", Time.current)
    else
      AdminReservation.where("SUBTIME(reserve_start_at, MAKETIME(expires_mins_before DIV 60, expires_mins_before MOD 60, 0)) < ?", Time.current)
    end
  end

end

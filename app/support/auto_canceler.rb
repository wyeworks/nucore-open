# frozen_string_literal: true

class AutoCanceler

  AdminStruct = Struct.new(:id)

  def cancel_reservations
    return if cancelable_reservations.none?
    cancelable_reservations.each do |res|
      next if res.order_detail.blank?
      cancel_reservation(res)
    end
  end

  def cancelable_reservations
    @cancelable_reservations ||= Reservation
                                 .joins(:product, order_detail: :order)
                                 .not_started
                                 .not_ended
                                 .not_canceled
                                 .where("auto_cancel_mins IS NOT NULL AND auto_cancel_mins > 0")
                                 .where(order_details: { state: %w(new inprocess) })
                                 .where(time_condition, now: Time.current)
                                 .merge(Order.purchased)
                                 .readonly(false)
  end

  def cancel_reservation(res)
    res.order_detail.cancel_reservation(admin, admin: true, admin_with_cancel_fee: true, canceled_reason: "auto canceled by system")
  rescue => e
    puts "Could not auto cancel reservation #{res.id}! #{e.message}\n#{e.backtrace.join("\n")}"
  end

  private

  def time_condition
    if Nucore::Database.oracle?
      "(to_timestamp(:now) - reserve_start_at) >= NumToDSInterval(auto_cancel_mins, 'MINUTE')"
    else
      "TIMESTAMPDIFF(MINUTE, reserve_start_at, :now) >= auto_cancel_mins"
    end
  end

  def admin
    # we need something that responds to #id to satisfy OrderDetail#cancel_reservation
    admin = AdminStruct.new
    admin.id = 0
    admin
  end

end

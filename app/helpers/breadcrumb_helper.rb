# frozen_string_literal: true

module BreadcrumbHelper
  def order_reservation_breadcrumb
    link_to my_breadcrumb_label, my_breadcrumb_path
  end

  private

  def my_breadcrumb_label
    if @active_tab == "reservations"
      t_my(Reservation)
    else
      t_my(Order)
    end
  end

  def my_breadcrumb_path
    public_send("#{@active_tab}_path")
  end
end

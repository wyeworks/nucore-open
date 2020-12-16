# frozen_string_literal: true

require "csv"

class Reports::AccountTransactionsReport

  include ApplicationHelper
  include ERB::Util
  include TextHelpers::Translation

  def initialize(order_details, options = {})
    @order_details = order_details
    @date_range_field = options[:date_range_field] || "fulfilled_at"
  end

  def to_csv
    report = []

    report << CSV.generate_line(headers)

    @order_details.find_each do |od|
      report << CSV.generate_line(build_row(od))
    end

    report.join
  end

  def filename
    "transaction_report.csv"
  end

  def description
    text(".subject")
  end

  def text_content
    text(".body")
  end

  def has_attachment?
    true
  end

  def translation_scope
    "reports.account_transactions"
  end

  private

  def headers
    [
      Order.model_name.human,
      OrderDetail.model_name.human,
      OrderDetail.human_attribute_name(@date_range_field),
      Facility.model_name.human,
      OrderDetail.human_attribute_name(:description),
      Reservation.human_attribute_name(:reserve_start_at),
      Reservation.human_attribute_name(:reserve_end_at),
      Reservation.human_attribute_name(:actual_start_at),
      Reservation.human_attribute_name(:actual_end_at),
      OrderDetail.human_attribute_name(:quantity),
      OrderDetail.human_attribute_name(:user),
      OrderDetail.human_attribute_name(:cost),
      OrderDetail.human_attribute_name(:subsidy),
      OrderDetail.human_attribute_name(:total),
      "#{Account.model_name.human} #{Account.human_attribute_name(:description)}",
      Account.model_name.human,
      Account.human_attribute_name(:owner),
      Account.human_attribute_name(:expires_at),
      OrderDetail.human_attribute_name(:order_status),
      OrderDetail.human_attribute_name(:note),
      text(".order_detail_notices"),
    ]
  end

  def build_row(order_detail)
    # Reservation.new acts as null object
    reservation = order_detail.reservation || Reservation.new
    order_detail = OrderDetailPresenter.new(order_detail)

    [
      order_detail.order.id,
      order_detail.id,
      format_usa_date(order_detail.send(:"#{@date_range_field}")),
      order_detail.order.facility,
      order_detail.description_as_html,
      format_usa_datetime(reservation.reserve_start_at),
      format_usa_datetime(reservation.reserve_end_at),
      format_usa_datetime(order_detail.time_data.try(:actual_start_at)),
      format_usa_datetime(order_detail.time_data.try(:actual_end_at)),
      order_detail_duration(order_detail),
      order_detail.order.user.full_name,
      order_detail.display_cost,
      order_detail.display_subsidy,
      order_detail.display_total,
      order_detail.account.description,
      order_detail.account.account_number,
      order_detail.account.owner_user,
      format_usa_date(order_detail.account.expires_at),
      order_detail.order_status,
      order_detail.note,
      notices_for(order_detail),
    ]
  end

  private

  def notices_for(order_detail)
    OrderDetailNoticePresenter.new(order_detail).badges_to_text
  end

  def order_detail_duration(order_detail)
    if order_detail.problem?
      ""
    else
      order_detail.csv_quantity
    end
  end

end

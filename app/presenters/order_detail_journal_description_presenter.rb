# frozen_string_literal: true

class OrderDetailJournalDescriptionPresenter < SimpleDelegator
  def long_description
    "##{self}: #{order.user.full_name(suspended_label: false)}: #{I18n.l(fulfilled_at.to_date, format: :usa)}: "\
    "#{product} x#{quantity}"
  end
end

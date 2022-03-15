# frozen_string_literal: true

class InstrumentIssue

  include ActiveModel::Model

  attr_accessor :message, :user, :product, :order_detail

  validates :message, presence: true
  validates :user, presence: true
  validates :product, presence: true
  validates :order_detail, presence: true

  def send_notification
    return false unless valid?

    InstrumentIssueMailer.create(
      product: product,
      user: user,
      message: message,
      order_detail: order_detail,
      recipients: recipients.to_a,
    ).deliver_later
  end

  def recipients
    if product.issue_report_recipients.present?
      product.issue_report_recipients
    else
      # Per NU, `Facility#email` is intentionally left out #137686
      all = product.facility.director_and_admins.pluck(:email) + product.training_request_contacts
      all.uniq
    end
  end

end

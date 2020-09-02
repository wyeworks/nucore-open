# frozen_string_literal: true

class InstrumentIssueMailerPreview < ActionMailer::Preview

  def create
    reservation = Nucore::Database.random(Reservation.user)
    InstrumentIssueMailer.create(
      product: reservation.product,
      user: reservation.user,
      message: "I am having a problem with the #{reservation.product}.\n\nPlease help!",
      recipients: InstrumentIssue.new(product: reservation.product).recipients,
    )
  end

end

class PurchaseNotifierPreview < ActionMailer::Preview

  def sanger_order_notification
    submission = NUCore::Database.random(SangerSequencing::Submission.joins(:order_detail).merge(OrderDetail.purchased))
    order_detail = submission.order_detail
    PurchaseNotifier.order_notification(
      order_detail.order,
      order_detail.user,
    )
  end

end

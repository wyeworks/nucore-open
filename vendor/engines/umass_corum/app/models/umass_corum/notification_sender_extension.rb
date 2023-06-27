# frozen_string_literal: true

module UmassCorum

  module NotificationSenderExtension

    def auto_dispute_order_details
      order_details_to_auto_dispute.each do |order_detail|
        order_detail.dispute_by = order_detail.account.auto_dispute_by
        order_detail.dispute_reason = "Subsidy account balance review"
        order_detail.dispute_at = Time.zone.now
        order_detail.save
      end
    end

    def order_details_to_auto_dispute
      order_details.filter { |od| od.account.auto_dispute_by.present? }
    end

  end

end

# frozen_string_literal: true

module OrderDetails

  class DisputeResolvedNotifier < SimpleDelegator

    def notify
      if saved_change_to_dispute_resolved_at? && dispute_resolved_at_before_last_save.blank?

        users_to_notify.each do |user|
          OrderDetailDisputeMailer.dispute_resolved(order_detail: __getobj__, user: user).deliver_later
        end
      end
    end

    private

    def users_to_notify
      ([dispute_by] + account.administrators).compact.uniq
    end

  end

end

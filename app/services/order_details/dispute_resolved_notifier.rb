# frozen_string_literal: true

module OrderDetails

  class DisputeResolvedNotifier < SimpleDelegator

    attr_accessor :current_user

    def initialize(order_detail, current_user: nil)
      @current_user = current_user
      super(order_detail)
    end

    def notify
      if resolve_dispute?
        users_to_notify.each do |user|
          OrderDetailDisputeMailer.dispute_resolved(order_detail: __getobj__, user: user).deliver_later
        end
        LogEvent.log( __getobj__, :resolve, @current_user)
      end
    end

    private

    def users_to_notify
      ([dispute_by] + account.administrators).compact.uniq
    end

  end

end

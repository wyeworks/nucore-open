# frozen_string_literal: true

module UmassCorum

  module VoucherSplitHelper

    def mivp_total(order_detail)
      mivp_percent = order_detail.account.mivp_split.percent
      mivp_cost = percentage(mivp_percent, order_detail.actual_total)
      number_to_currency(mivp_cost)
    end

    def primary_total(order_detail)
      primary_percent = order_detail.account.primary_split.percent
      primary_cost = percentage(primary_percent, order_detail.actual_total)
      number_to_currency(primary_cost)
    end

    def percentage(percent, total)
      (percent / 100) * total
    end

  end

end

# frozen_string_literal: true

module UmassCorum

  module VoucherOrderStatus

    def self.mivp
      OrderStatus.find_or_create_by(name: "MIVP Pending")
    end

  end

end

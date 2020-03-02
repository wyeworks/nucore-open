# frozen_string_literal: true

module GlobalSearch

  class OrderSearcher < Base

    include Nucore::Database::CaseSensitivityHelper

    def template
      "order_details"
    end

    private

    def search
      query.gsub!(/\s/, "")

      relation = case query
                 when /\A\d+-\d+\z/
                   search_full(query)
                 when /\A[A-Za-z]+-\d+\z/
                   search_external query
                 when /\A\d+\z/
                   OrderDetail.where("order_details.id = :id OR order_details.order_id = :id", id: query)
      end

      relation ? relation.joins(:order).purchased : []
    end

    def search_full(query)
      order_id, order_detail_id = query.split("-")
      OrderDetail.where(id: order_detail_id, order_id: order_id)
    end

    def search_external(query)
      insensitive_where OrderDetail.joins(:external_service_receiver), "external_service_receivers.external_id", query
    end

  end

end

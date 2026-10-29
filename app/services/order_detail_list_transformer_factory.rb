# frozen_string_literal: true

class OrderDetailListTransformerFactory
  @@klass = Settings.order_details.list_transformer.constantize

  def self.instance(*)
    @@klass.new(*)
  end
end

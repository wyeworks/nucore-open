# frozen_string_literal: true

module OrderDetail::Notices
  extend ActiveSupport::Concern

  included do
    serialize :notices, Array
    serialize :problems, Array
  end

  def update_notices
    OrderDetailNoticesUpdater.perform_now(self)
  end

  def update_notices_later
    OrderDetailNoticesUpdater.perform_later(self)
  end
end

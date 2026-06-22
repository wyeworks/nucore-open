# frozen_string_literal: true

##
# Job to run SlotAvailableService.notfy! async
#
class SlotAvailableJob < ApplicationJob
  def perform(product, start_time, end_time, exclude_user: nil)
    ProductNotifications::SlotAvailableService.new(
      product, start_time, end_time, exclude_user:
    ).notify!
  end
end

# frozen_string_literal: true

##
# Patch to retry on chromdriver issue that causes:
#
#  Selenium::WebDriver::Error::UnknownError:
#    unknown error: unhandled inspector error: {
#      "code":-32000,
#      "message":"Node with given id does not belong to the document"
#    }
#
# See https://issues.chromium.org/issues/375343406
#
module CapybaraStaleNodeRetry
  STALE_NODE_MESSAGE = "does not belong to the document"

  def catch_error?(error, errors = nil)
    return true if stale_node_error?(error)

    super
  end

  private

  def stale_node_error?(error)
    error.is_a?(Selenium::WebDriver::Error::UnknownError) &&
      error.message.to_s.include?(STALE_NODE_MESSAGE)
  end
end

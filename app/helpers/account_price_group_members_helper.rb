# frozen_string_literal: true

module AccountPriceGroupMembersHelper
  # Provides a notice, if the number of search results found is above the
  # limit.
  #
  # +count+ The total number of accounts there were found in the search
  #
  # +limit+ The maximum number of accounts that will be displayed
  def additional_results_notice(count:, limit:)
    # This ensures that count and limit exist before attemtping to use
    # them, and will silently exit if they don't.
    #
    # This should never happen, so this method is mainly here to handle
    # the case that one of these has been inappropriately deleted.
    if count.nil? || limit.nil?
      if defined?(Rollbar)
        Rollbar.info("Argument missing in additional_results_notice", count: count, limit: limit)
      end
    elsif count > limit
      t("account_price_group_members.search_results.notice_html", count: count - limit)
    end
  end
end

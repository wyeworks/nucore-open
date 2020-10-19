# frozen_string_literal: true

# Based on http://launchware.com/articles/acceptance-testing-asserting-sort-order
# Matcher to decribe the expected display order in the DOM.
# Pass in an array of Strings in the expected display order.
#
# Usage:
# visit timeline_facility_reservations_path(facility)
# expect(["First", "Second", "Third"]).to appear_in_order
RSpec::Matchers.define :appear_in_order do
  match do |expected_order|
    actual_order = actual_order_for(expected_order)
    actual_order == expected_order
  end

  failure_message do |expected_order|
    actual_order = actual_order_for(expected_order)
    "expected #{expected_order}, but actual order was #{actual_order}"
  end

  def actual_order_for(expected_content)
    actual_order = expected_content.map do |content|
      next if page.body.index(content).nil?

      [content, page.body.index(content)]
    end
    actual_order.compact.sort_by(&:last).map(&:first)
  end
end

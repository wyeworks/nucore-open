# frozen_string_literal: true

module OrderDetail::Notices
  extend ActiveSupport::Concern

  included do
    # Rails 7.2 changed how columns are automatically serialized. Without explicit
    # serialize declarations, symbols in arrays are converted to strings when read
    # from the database. We explicitly use YAML serialization to preserve symbols.
    serialize :notice_keys, coder: YAML, type: Array
    serialize :problem_keys, coder: YAML, type: Array

    before_save :set_problem_and_notices
    before_save :update_fulfilled_at_on_resolve
  end

  def set_problem_and_notices
    notice_service = OrderDetails::NoticesService.new(self)

    self.problem_keys = notice_service.problems
    self.notice_keys = notice_service.notices
    self.problem = problem_keys.present?
  end

  # This must be called after updating problem field
  def update_fulfilled_at_on_resolve
    return unless time_data.present? &&
                  problem_changed? &&
                  !problem_order? &&
                  time_data.actual_end_at.present?

    self.fulfilled_at = time_data.actual_end_at
  end
end

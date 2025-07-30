# frozen_string_literal: true

module OrderDetail::Notices
  extend ActiveSupport::Concern

  included do
    serialize :notices, Array
    serialize :problems, Array

    before_save :set_problem_and_notices
  end

  def set_problem_and_notices
    notice_service = OrderDetails::NoticesService.new(self)
    self.problems = notice_service.problems
    self.notices = notice_service.notices

    self.problem = problems.present?
    update_fulfilled_at_on_resolve if time_data.present?
  end

  def update_fulfilled_at_on_resolve
    if problem_changed? && !problem_order? && time_data.actual_end_at
      self.fulfilled_at = time_data.actual_end_at
    end
  end
end

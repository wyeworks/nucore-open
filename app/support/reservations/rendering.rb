# frozen_string_literal: true

# Support for displaying Reservations in various formats
module Reservations::Rendering

  extend ActiveSupport::Concern

  included do
    delegate :to_s, :reserve_to_s, :actuals_string, to: :time_presenter
    delegate :as_calendar_object, to: :calendar_presenter
  end

  class_methods do
    def as_calendar_objects(reservations, options = {})
      Array(reservations).map { |r| r.as_calendar_object(options) }
    end
  end

  def display_start_at
    actual_start_at || reserve_start_at
  end

  def display_end_at
    actual_end_at || reserve_end_at
  end

  private

  def time_presenter
    Reservations::TimesPresenter.new(self)
  end

  def calendar_presenter
    Reservations::CalendarPresenter.build(self)
  end

end

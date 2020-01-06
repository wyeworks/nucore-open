# frozen_string_literal: true

# Support for reading/writing reservation and actual start and
# end times using values split across text inputs
module Reservations::DateSupport

  extend ActiveSupport::Concern

  included do
    attr_writer :duration_mins, :actual_duration_mins,
                :reserve_start_date, :reserve_start_hour, :reserve_start_min, :reserve_start_meridian,
                :actual_start_date, :actual_start_hour, :actual_start_min, :actual_start_meridian,
                :actual_end_date, :actual_end_hour, :actual_end_min, :actual_end_meridian

    # Use only in tests to make creation a little easier
    attr_accessor :split_times
    before_validation :set_all_split_times, if: :split_times
  end

  def assign_times_from_params(params)
    assign_reserve_from_params(params) if admin_editable?
    assign_actuals_from_params(params) if can_edit_actuals?

    set_all_split_times
  end

  #
  # Virtual attributes
  #
  def reserve_start_hour
    hour_field(:reserve_start)
  end

  def reserve_start_min
    min_field(:reserve_start)
  end

  def reserve_start_meridian
    meridian_field(:reserve_start)
  end

  def reserve_end_hour
    hour_field(:reserve_end)
  end

  def reserve_start_date
    date_field(:reserve_start)
  end

  def reserve_end_min
    min_field(:reserve_end)
  end

  def reserve_end_meridian
    meridian_field(:reserve_end)
  end

  def reserve_end_date
    date_field(:reserve_end)
  end

  def duration_mins
    if @duration_mins
      @duration_mins.to_i
    elsif reserve_end_at && reserve_start_at
      TimeRange.new(reserve_start_at, reserve_end_at).duration_mins
    else
      0
    end
  end

  # If the reservation is ongoing, we sometimes want to know how long a currently
  # running reservation has been running for (e.g. accessories).
  def actual_or_current_duration_mins
    actual_duration_mins(actual_end_fallback: Time.current)
  end

  def actual_duration_mins(actual_end_fallback: nil)
    if @actual_duration_mins
      @actual_duration_mins.to_i
    elsif actual_start_at
      TimeRange.new(actual_start_at, actual_end_at || actual_end_fallback).duration_mins
    else
      0
    end
  end

  def actual_start_date
    date_field(:actual_start)
  end

  def actual_start_hour
    hour_field(:actual_start)
  end

  def actual_start_min
    min_field(:actual_start)
  end

  def actual_start_meridian
    meridian_field(:actual_start)
  end

  def actual_end_date
    date_field(:actual_end)
  end

  def actual_end_hour
    hour_field(:actual_end)
  end

  def actual_end_min
    min_field(:actual_end)
  end

  def actual_end_meridian
    meridian_field(:actual_end)
  end

  def has_actual_times?
    actual_start_at.present? && actual_end_at.present?
  end

  def has_reserved_times?
    reserve_start_at.present? && reserve_end_at.present?
  end

  private

  def instance_variable_fetch(field, options = {})
    options.reverse_merge!(to_i: false)
    result = instance_variable_get("@#{field}") || yield
    result = result.to_i if options[:to_i]
    result
  end

  def date_field(field)
    instance_variable_fetch("#{field}_date") do
      send("#{field}_at").try(:strftime, "%m/%d/%Y")
    end
  end

  def hour_field(field)
    instance_variable_fetch("#{field}_hour", to_i: true) do
      human_hour(send("#{field}_at"))
    end
  end

  def meridian_field(field)
    instance_variable_fetch("#{field}_meridian") do
      send("#{field}_at").try(:strftime, "%p")
    end
  end

  def min_field(field)
    instance_variable_fetch("#{field}_min", to_i: true) do
      send("#{field}_at").try(:min)
    end
  end

  def human_hour(time)
    return unless time
    hour = time.hour.to_i % 12
    hour == 0 ? 12 : hour
  end

  def set_all_split_times
    set_reserve_start_at
    set_reserve_end_at
    set_actual_start_at
    set_actual_end_at
  end

  def assign_reserve_from_params(params)
    reserve_attrs = params.slice(:reserve_start_date, :reserve_start_hour, :reserve_start_min, :reserve_start_meridian,
                                 :duration_mins,
                                 :reserve_start_at, :reserve_end_at)
    # need to be reset to nil so the individual pieces will
    # take precedence, but only reset them if we're going to overwrite them

    self.reserve_start_at = nil if reserve_attrs.keys.any? { |k| k.to_s.start_with?("reserve_start") }
    self.reserve_end_at   = nil if reserve_attrs.keys.any? { |k| k.to_s.start_with?("reserve_end") } || reserve_attrs.key?(:duration_mins)

    assign_attributes reserve_attrs
  end

  def assign_actuals_from_params(params)
    reserve_attrs = params.slice(:actual_start_date, :actual_start_hour, :actual_start_min, :actual_start_meridian,
                                 :actual_end_date, :actual_end_hour, :actual_end_min, :actual_end_meridian,
                                 :actual_start_at, :actual_end_at, :actual_duration_mins)


    reserve_attrs.reject! { |_key, value| value.blank? }

    self.actual_start_at = nil if reserve_attrs.keys.any? { |k| k.to_s.start_with?("actual_start") }
    self.actual_end_at = nil if reserve_attrs.keys.any? { |k| k.to_s.start_with?("actual_end") } || reserve_attrs.key?(:actual_duration_mins)

    assign_attributes reserve_attrs
  end

  # set set_reserve_start_at based on reserve_start_xxx virtual attributes
  def set_reserve_start_at
    return unless reserve_start_at.blank?
    if @reserve_start_date && @reserve_start_hour && @reserve_start_min && @reserve_start_meridian
      self.reserve_start_at = parse_usa_date(@reserve_start_date, "#{@reserve_start_hour}:#{@reserve_start_min.to_s.rjust(2, '0')} #{@reserve_start_meridian}")
    end
  end

  # set reserve_end_at based on duration_mins
  def set_reserve_end_at
    return if reserve_end_at.present? || reserve_start_at.blank? || @duration_mins.nil?

    self.reserve_end_at = reserve_start_at + @duration_mins.to_i.minutes
  end

  def set_actual_start_at
    return if actual_start_at.present?
    if @actual_start_date && @actual_start_hour && @actual_start_min && @actual_start_meridian
      self.actual_start_at = parse_usa_date(@actual_start_date, "#{@actual_start_hour}:#{@actual_start_min.to_s.rjust(2, '0')} #{@actual_start_meridian}")
    end
  end

  def set_actual_end_at
    return if actual_end_at.present?
    if @actual_end_date && @actual_end_hour && @actual_end_min && @actual_end_meridian
      self.actual_end_at = parse_usa_date(@actual_end_date, "#{@actual_end_hour}:#{@actual_end_min.to_s.rjust(2, '0')} #{@actual_end_meridian}")
    elsif @actual_duration_mins && actual_start_at
      self.actual_end_at = actual_start_at + @actual_duration_mins.to_i.minutes
    end
  end

end

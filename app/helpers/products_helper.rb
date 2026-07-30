# frozen_string_literal: true

module ProductsHelper

  def price_policy_errors(product)
    if product.is_a?(Bundle)
      error_msg = t("price_policies.errors.missing_for_bundle") if product.products_missing_price_policies.any?
    elsif product.current_price_policies.none?
      error_msg = t("price_policies.errors.none_exist")
    end
    content_tag :span, error_msg, class: ["label", "label-danger", "pull-right"] if error_msg
  end

  def options_for_control_mechanism
    Relay::CONTROL_MECHANISMS.inject(ActiveSupport::OrderedHash.new) do |hash, (key, _v)|
      human_value = t("instruments.instrument_fields.relay.control_mechanisms.#{key}")
      hash[human_value] = key
      hash
    end
  end

  def options_for_relay
    [
      if SettingsHelper.feature_on?("products.disable_relay_synaccess_rev_a")
          nil
      else
        [RelaySynaccessRevA, RelaySynaccessRevA.name]
      end,
      [RelaySynaccessRevB, RelaySynaccessRevB.name],
      [RelayDataprobe, RelayDataprobe.name],
    ].compact
  end

  def instrument_pricing_modes
    Instrument::PRICING_MODES.reject do |pricing_mode|
      (pricing_mode == Instrument::Pricing::SCHEDULE_DAILY && cannot?(:create_daily_booking, Instrument)) ||
        (pricing_mode == Instrument::Pricing::DURATION && cannot?(:create_duration_billing, Instrument))
    end
  end

  def timed_service_pricing_mode_label(pricing_mode)
    key = case pricing_mode
          when TimedService::Pricing::DURATION then "duration"
          when TimedService::Pricing::STANDARD then "standard"
          end

    text("timed_services.timed_service_fields.pricing_modes.#{key}")
  end

  def timed_service_pricing_modes
    modes = TimedService::PRICING_MODES
    modes -= [TimedService::Pricing::DURATION] if cannot?(:create_duration_billing, TimedService)

    modes.map { |mode| [timed_service_pricing_mode_label(mode), mode] }
  end

  def public_calendar_link(product, availability = nil)
    return unless product.respond_to? :reservations

    opts = if product.facility.show_instrument_availability?
      public_calendar_availability_options(product, availability)
    else
      { class: ["fa fa-calendar fa-lg fa-fw"], title: t("instruments.public_schedule.icon") }
    end

    link_to "", facility_instrument_public_schedule_path(product.facility, product), opts
  end

  def show_buttons_to_control_all_relays?(products)
    products.first.is_a?(Instrument) && products.includes(:relay).select(&:has_real_relay?).any?
  end

  private

  def public_calendar_availability_options(product, availability = nil)
    availability ||= Instruments::AvailabilityStatus.new(product.facility)

    if product.offline?
      { class: ["fa fa-calendar fa-lg fa-fw", "in-use"],
        title: text("instruments.offline.note") }
    elsif availability.available_now?(product)
      { class: ["fa fa-calendar fa-lg fa-fw", "available"],
        title: text("instruments.public_schedule.available") }
    else
      { class: ["fa fa-calendar fa-lg fa-fw", "in-use"],
        title: text("instruments.public_schedule.unavailable") }
    end
  end

end

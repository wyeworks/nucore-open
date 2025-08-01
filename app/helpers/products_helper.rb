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
      if SettingsHelper.feature_on?(:disable_relay_synaccess_rev_a)
          nil
      else
        [RelaySynaccessRevA, RelaySynaccessRevA.name]
      end,
      [RelaySynaccessRevB, RelaySynaccessRevB.name],
      [RelayDataprobe, RelayDataprobe.name],
    ].compact
  end

  def instrument_pricing_modes
    return Instrument::PRICING_MODES if can?(:create_daily_booking, Instrument)

    Instrument::PRICING_MODES.reject do |pricing_mode|
      pricing_mode == Instrument::Pricing::SCHEDULE_DAILY
    end
  end

  def public_calendar_link(product)
    return unless product.respond_to? :reservations

    opts = if product.facility.show_instrument_availability?
      public_calendar_availability_options(product)
    else
      { class: ["fa fa-calendar fa-lg fa-fw"], title: t("instruments.public_schedule.icon") }
    end

    link_to "", facility_instrument_public_schedule_path(product.facility, product), opts
  end

  def show_buttons_to_control_all_relays?(products)
    products.first.is_a?(Instrument) && products.includes(:relay).select(&:has_real_relay?).any?
  end

  private

  def public_calendar_availability_options(product)
    if product.offline?
      { class: ["fa fa-calendar fa-lg fa-fw", "in-use"],
        title: text("instruments.offline.note") }
    elsif product.walkup_available?
      { class: ["fa fa-calendar fa-lg fa-fw", "available"],
        title: text("instruments.public_schedule.available") }
    else
      { class: ["fa fa-calendar fa-lg fa-fw", "in-use"],
        title: text("instruments.public_schedule.unavailable") }
    end
  end

end

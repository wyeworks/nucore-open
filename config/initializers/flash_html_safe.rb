# frozen_string_literal: true

module FlashHtmlSafe
  SESSION_KEY = "html_safe"

  module ClassMethods
    def from_session_value(value)
      flash = super
      flash.mark_html_safe(value[SESSION_KEY]) if value.is_a?(Hash)
      flash
    end
  end

  def self.prepended(base)
    base.singleton_class.prepend(ClassMethods)
  end

  def to_session_value
    value = super
    return value if value.nil?

    html_safe_keys = value["flashes"].select { |_key, message| message.is_a?(String) && message.html_safe? }.keys
    html_safe_keys.empty? ? value : value.merge(SESSION_KEY => html_safe_keys)
  end

  def mark_html_safe(keys)
    Array(keys).each do |key|
      @flashes[key] = @flashes[key].html_safe if @flashes[key].is_a?(String)
    end
  end
end

ActionDispatch::Flash::FlashHash.prepend(FlashHtmlSafe)

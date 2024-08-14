# frozen_string_literal: true

module BootstrapHelper

  def modal_close_button
    content_tag :button, "x",
                :class => "close",
                :data => { dismiss: "modal" },
                "aria_hidden" => true,
                :type => "button"
  end

  def modal_cancel_button(options = {})
    data = { dismiss: "modal" }
    class_name = "btn"

    data.merge!(options[:data]) if options[:data]
    class_name = "#{class_name} #{options[:class_name]}" if options[:class_name]

    if request.xhr?
      content_tag :button,
                  options[:text] || "Cancel",
                  data:,
                  class: class_name,
                  type: "button"
    end
  end

  def status_badge(order_detail)
    classes = ["label", "status-#{order_detail.order_status.root.name.underscore}"]
    content_tag :span, order_detail.order_status, class: classes
  end

  def tooltip_icon(icon_class, tooltip)
    content_tag :i, "", class: icon_class, data: { toggle: "tooltip" }, title: tooltip
  end

end

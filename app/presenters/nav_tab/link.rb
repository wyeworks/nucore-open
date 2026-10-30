# frozen_string_literal: true

class NavTab::Link
  include ActionView::Helpers::UrlHelper

  attr_reader :subnav, :text, :url

  def initialize(tab: nil, text: nil, url: nil, subnav: nil, cross_facility: false)
    @tab = tab.presence.to_s
    @text = text || I18n.t("pages.#{tab}")
    @url = url
    @subnav = subnav
    @cross_facility = cross_facility
  end

  def active?(controller)
    return false if controller.active_tab != @tab

    controller.cross_facility? ? @cross_facility : !@cross_facility
  end

  def tab_class(controller)
    active?(controller) ? "active" : ""
  end

  def tab_id
    "#{@tab}_tab" if @tab.present?
  end

  def to_html
    url.present? ? link_to(text, url) : text
  end
end

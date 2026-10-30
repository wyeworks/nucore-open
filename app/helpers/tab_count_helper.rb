# frozen_string_literal: true

module TabCountHelper
  ACTIONS_TO_COUNT_TYPE = {
    index: :new_or_in_process_orders,
    show_problems: :problem_order_details,
  }.freeze

  def tab_counts
    @counts = {}
    ACTIONS_TO_COUNT_TYPE.values.each do |count|
      @counts[count] = send(count).count if params[:tabs].include? count.to_s
    end
    render json: @counts
  end

  def display_tab(title, link, args)
    active = tab_active?(args[:action])
    if active
      title << " (#{@order_details.try(:total_entries) || @order_details.count})"
    end
    content_tag(:li, class: active ? "active" : nil) do
      link_to title, link, id: ACTIONS_TO_COUNT_TYPE[args[:action]], class: "js-tab-counts"
    end
  end

  def tab_active?(action)
    params[:action].to_sym == action.to_sym
  end

  def tab(title, link, active = nil, options = {})
    active = (request.path == link) if active.nil?
    classes = []
    classes << "active" if active
    classes.concat [*options[:class]]

    content_tag(:li, class: classes) do
      link_to title, link, options[:link_options]
    end
  end
end

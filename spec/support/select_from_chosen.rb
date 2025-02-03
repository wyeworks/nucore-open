# frozen_string_literal: true

module SelectFromChosen

  # Allow running system specs with JS enabled and still access 'chosen' select inputs
  # Add options[:scroll_to] to solve error `element click intercepted: Element is not clickable at point (,). Other element would receive the click`
  def select_from_chosen(item_text, options)
    page.scroll_to(options[:scroll_to]) if options[:scroll_to]

    field = find_field(options[:from], visible: false)
    find("##{field[:id]}_chosen").click
    find("##{field[:id]}_chosen ul.chosen-results li", text: item_text).click
  end

  def unselect_from_chosen(item_text, options)
    page.scroll_to(options[:scroll_to]) if options[:scroll_to]

    field = find_field(options[:from], visible: false)
    find("##{field[:id]}_chosen li.search-choice", text: item_text).find(".search-choice-close").click
  end

end

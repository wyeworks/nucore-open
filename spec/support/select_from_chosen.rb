# frozen_string_literal: true

module SelectFromChosen

  # Allow running system specs with JS enabled and still access 'chosen' select inputs
  def select_from_chosen(item_text, options)
    field = find_field(options[:from], visible: false)
    find("##{field[:id]}_chosen").click
    find("##{field[:id]}_chosen ul.chosen-results li", text: item_text).click
  end

end

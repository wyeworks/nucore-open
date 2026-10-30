# frozen_string_literal: true

module CheckboxHelper
  def select_all_link(start_none: false)
    starting_text = start_none ? text("shared.select_none") : text("shared.select_all")
    link_to starting_text, "#",
            class: "js--select_all",
            data: { select_all: text("shared.select_all"), select_none: text("shared.select_none") }
  end
end

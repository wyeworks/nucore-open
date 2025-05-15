# frozen_string_literal: true

module UserSelect
  def select_user(selector, user)
    page.execute_script("$('#{selector}').trigger('mousedown')")
    page.execute_script("$('#{selector} .chosen-search input').val('#{user.first_name}').trigger('input')")

    wait_for_ajax

    find("#{selector}").click
    select_from_chosen user.full_name, from: "User"
  end
end

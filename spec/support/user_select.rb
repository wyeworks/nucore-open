# frozen_string_literal: true

module UserSelect
  def select_user(user)
    page.execute_script("$('#estimate_user_id_chosen').trigger('mousedown')")
    page.execute_script("$('#estimate_user_id_chosen .chosen-search input').val('#{user.first_name}').trigger('input')")

    wait_for_ajax

    find("#estimate_user_id_chosen").click
    select_from_chosen user.full_name, from: "User"
  end
end

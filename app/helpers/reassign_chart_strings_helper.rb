# frozen_string_literal: true

module ReassignChartStringsHelper

  def available_account_select_tag(form, accounts)
    form.input :account_id,
               as: :select,
               collection: accounts,
               label_method: :account_list_item,
               label: Account.model_name.human,
               input_html: {
                 class: "account_selection",
                 data: {
                   placeholder: text("shared.transactions.reassign_chart_strings.account_select.placeholder"),
                 },
               }
  end

end

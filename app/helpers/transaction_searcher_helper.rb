# frozen_string_literal: true

module TransactionSearcherHelper
  def searcher_input(form, searcher)
    case searcher.input_type
    when :transaction_chosen, :select then select_input(form, searcher)
    when :boolean then boolean_input(form, searcher)
    else
      raise ArgumentError, "Unsupported transaction searcher input type: #{searcher.input_type}"
    end
  end

  private

  def select_input(form, searcher)
    form.input(
      searcher.key,
      as: searcher.input_type,
      collection: searcher.options,
      label: searcher.label,
      label_method: searcher.label_method,
      data_attrs: searcher.method(:data_attrs),
      input_html: { id: searcher.key, class: "quarter-width" },
      include_blank: false
    )
  end

  def boolean_input(form, searcher)
    form.input(
      searcher.key,
      as: :boolean,
      label: false,
      inline_label: searcher.label,
      data_attrs: searcher.method(:data_attrs),
      input_html: { id: searcher.key },
    )
  end
end

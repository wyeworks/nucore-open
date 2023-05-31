# frozen_string_literal: true

class AddSkipMissingFormToOrderDetails < ActiveRecord::Migration[6.1]
  def change
    # The order_details table has ~1.4m records for NU,
    # so adding default values is a little tricky:
    # https://dev.to/lucasprag/how-to-add-columns-with-default-to-large-tables-8mc
    # We are only setting the value to true in rare cases
    # so it didn't seem worth the added risk/trouble.
    add_column :order_details, :skip_missing_form, :boolean
  end
end

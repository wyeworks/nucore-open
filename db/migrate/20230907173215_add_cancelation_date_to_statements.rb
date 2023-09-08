# frozen_string_literal: true

class AddCancelationDateToStatements < ActiveRecord::Migration[6.1]
  def change
    add_column :statements, :canceled_at, :datetime
  end
end

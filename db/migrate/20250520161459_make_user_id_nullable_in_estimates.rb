# frozen_string_literal: true

class MakeUserIdNullableInEstimates < ActiveRecord::Migration[7.0]
  def change
    change_column_null :estimates, :user_id, true
  end
end

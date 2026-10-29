# frozen_string_literal: true

class FixProductDefaults < ActiveRecord::Migration[5.0]
  def up
    change_column_default :products, :requires_approval, false
    change_column_default :products, :is_archived, false
    change_column_default :products, :is_hidden, false
  end

  def down
    change_column_default :products, :requires_approval, nil
    change_column_default :products, :is_archived, nil
    change_column_default :products, :is_hidden, nil
  end
end

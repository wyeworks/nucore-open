# frozen_string_literal: true

class RenameExtraPennyToApplyRemainder < ActiveRecord::Migration[4.2]

  def change
    rename_column :splits, :extra_penny, :apply_remainder
  end

end

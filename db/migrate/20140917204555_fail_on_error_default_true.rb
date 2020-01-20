# frozen_string_literal: true

class FailOnErrorDefaultTrue < ActiveRecord::Migration[4.2]

  def up
    change_column :order_imports, :fail_on_error, :boolean, default: true
  end

  def down
    change_column :order_imports, :fail_on_error, :boolean, default: false
  end

end

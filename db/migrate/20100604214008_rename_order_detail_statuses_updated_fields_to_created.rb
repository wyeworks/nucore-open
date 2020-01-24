# frozen_string_literal: true

class RenameOrderDetailStatusesUpdatedFieldsToCreated < ActiveRecord::Migration[4.2]

  def self.up
    rename_column :order_detail_statuses, :updated_by, :created_by
    rename_column :order_detail_statuses, :updated_at, :created_at
  end

  def self.down
    rename_column :order_detail_statuses, :created_by, :updated_by
    rename_column :order_detail_statuses, :created_at, :updated_at
  end

end

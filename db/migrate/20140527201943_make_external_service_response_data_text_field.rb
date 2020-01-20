# frozen_string_literal: true

class MakeExternalServiceResponseDataTextField < ActiveRecord::Migration[4.2]

  def up
    add_column :external_service_receivers, :response_data_text, :text
    execute "UPDATE external_service_receivers SET response_data_text = response_data"
    remove_column :external_service_receivers, :response_data
    rename_column :external_service_receivers, :response_data_text, :response_data
  end

  def down
    add_column :external_service_receivers, :response_data_varchar, :string
    execute "UPDATE external_service_receivers SET response_data_varchar = response_data"
    remove_column :external_service_receivers, :response_data
    rename_column :external_service_receivers, :response_data_varchar, :response_data
  end

end

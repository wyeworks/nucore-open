# frozen_string_literal: true

class UpdatePoAndInvoiceFields < ActiveRecord::Migration[4.2]

  def self.up
    # add PO remit-to
    add_column :accounts, :remittance_information, :text, null: true
    # add facility_id to PO's
    add_column :accounts, :facility_id, :integer, null: true
    execute "ALTER TABLE accounts ADD CONSTRAINT fk_account_facility_id FOREIGN KEY (facility_id) REFERENCES facilities (id)"

    # add facility contact information
    add_column :facilities, :address, :text, null: true
    add_column :facilities, :phone_number, :string, null: true
    add_column :facilities, :fax_number, :string, null: true
    add_column :facilities, :email, :string, null: true
  end

  def self.down
    remove_column :accounts, :remittance_information
    remove_column :accounts, :facility_id
    remove_column :facilities, :address
    remove_column :facilities, :phone_number
    remove_column :facilities, :fax_number
    remove_column :facilities, :email
  end

end

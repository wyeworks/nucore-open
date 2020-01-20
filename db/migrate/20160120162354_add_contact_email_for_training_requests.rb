# frozen_string_literal: true

class AddContactEmailForTrainingRequests < ActiveRecord::Migration[4.2]

  def change
    add_column :products, :training_request_contacts, :text
  end

end

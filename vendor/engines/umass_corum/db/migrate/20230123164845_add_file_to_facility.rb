# frozen_string_literal: true

class AddFileToFacility < ActiveRecord::Migration[6.1]
  def change
    add_attachment :facilities, :file
  end
end

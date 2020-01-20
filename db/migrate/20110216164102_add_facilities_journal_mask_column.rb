# frozen_string_literal: true

class AddFacilitiesJournalMaskColumn < ActiveRecord::Migration[4.2]

  def self.up
    add_column :facilities, :journal_mask, :string, limit: 50, null: true # TODO: why? , :after =>
    i = 0
    Facility.all.each do |facility|
      i += 1
      execute "UPDATE facilities SET journal_mask = '#{sprintf('C%02d', i)}' WHERE id = #{facility.id}"
    end
    change_column :facilities, :journal_mask, :string, limit: 50, null: false
  end

  def self.down
    remove_column :facilities, :journal_mask
  end

end

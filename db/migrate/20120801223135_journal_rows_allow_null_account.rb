# frozen_string_literal: true

class JournalRowsAllowNullAccount < ActiveRecord::Migration[4.2]

  def self.up
    if Nucore::Database.oracle?
      execute "alter table journal_rows modify (account null)"
    else
      change_column :journal_rows, :account, :string, limit: 5, null: true
    end
  end

  def self.down
    if Nucore::Database.oracle?
      execute "alter table journal_rows modify (account not null)"
    else
      change_column :journal_rows, :account, :string, limit: 5, null: false
    end
  end

end

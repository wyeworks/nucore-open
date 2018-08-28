# frozen_string_literal: true

class JournalRowsAllowNullAccount < ActiveRecord::Migration

  def self.up
    if NUCore::Database.oracle?
      execute "alter table journal_rows modify (account null)"
    else
      change_column :journal_rows, :account, :string, limit: 5, null: true
    end
  end

  def self.down
    if NUCore::Database.oracle?
      execute "alter table journal_rows modify (account not null)"
    else
      change_column :journal_rows, :account, :string, limit: 5, null: false
    end
  end

end

# frozen_string_literal: true

class ChangeJournalRowsValuesToStrings < ActiveRecord::Migration[4.2]

  def self.up
    add_column :journal_rows, :fund_string,     :string, limit: 3, null: true, after: :fund
    add_column :journal_rows, :dept_string,     :string, limit: 7, null: true, after: :dept
    add_column :journal_rows, :project_string,  :string, limit: 8, null: true,  after: :project
    add_column :journal_rows, :activity_string, :string, limit: 2, null: true,  after: :activity
    add_column :journal_rows, :program_string,  :string, limit: 4, null: true,  after: :program
    add_column :journal_rows, :account_string,  :string, limit: 5, null: true, after: :account

    execute "UPDATE journal_rows SET fund_string = fund, dept_string = dept, project_string = project, activity_string = activity, program_string = program, account_string = account"

    remove_column :journal_rows, :fund
    remove_column :journal_rows, :dept
    remove_column :journal_rows, :project
    remove_column :journal_rows, :activity
    remove_column :journal_rows, :program
    remove_column :journal_rows, :account

    rename_column :journal_rows, :fund_string,     :fund
    rename_column :journal_rows, :dept_string,     :dept
    rename_column :journal_rows, :project_string,  :project
    rename_column :journal_rows, :activity_string, :activity
    rename_column :journal_rows, :program_string,  :program
    rename_column :journal_rows, :account_string,  :account

    change_column :journal_rows, :fund,     :string, limit: 3, null: false
    change_column :journal_rows, :dept,     :string, limit: 7, null: false
    change_column :journal_rows, :account,  :string, limit: 5, null: false

    # update existing activities
    JournalRow.all.each do |jr|
      unless jr.activity.blank?
        jr.activity = sprintf("%02d", jr.activity.to_i)
        jr.save
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end

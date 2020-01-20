# frozen_string_literal: true

class AddBudgetedChartString < ActiveRecord::Migration[4.2]

  def self.up
    create_table :budgeted_chart_strings do |t|
      t.string    :fund,        limit: 20, null: false
      t.string    :dept,        limit: 20, null: false
      t.string    :project,     limit: 20
      t.string    :activity,    limit: 20
      t.string    :account,     limit: 20
      t.datetime  :starts_at, null: false
      t.datetime  :expires_at, null: false
    end
  end

  def self.down
    drop_table :budgeted_chart_strings
  end

end

# frozen_string_literal: true

# In Rails <= 4.2, Rails mapped the Oracle `DATE` to Ruby's `DateTime`. As of Rails 5
# `DATE` maps to `Date`. We need to change it
class FixOracleTimestamps < ActiveRecord::Migration[5.0]

  def change
    return unless Nucore::Database.oracle?

    reversible do |dir|
      dir.up { change_all_columns_types(:date, :datetime) }
      dir.down { change_all_columns_types(:datetime, :date) }
    end
  end

  private

  def change_all_columns_types(from_type, to_type)
    ActiveRecord::Base.connection.tables.sort.each do |table_name|
      columns = ActiveRecord::Base.connection.columns(table_name).select { |c| c.type.to_s == from_type.to_s }

      next if columns.blank?

      columns.each do |c|
        change_column table_name, c.name, to_type
      end
    end
  end

end

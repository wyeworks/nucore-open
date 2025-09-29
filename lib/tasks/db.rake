# frozen_string_literal: true

namespace :db do
  def db_allow_task?
    if Rails.env.local?
      true
    else
      puts "Only allowed in development and test mode"
      false
    end
  end

  desc "Drop database for current RAILS_ENV"
  task oracle_drop: :environment do
    next unless db_allow_task?
    config = Rails.configuration.database_configuration[Rails.env]
    connect_string = "#{config['username']}/#{config['password']}@#{config['database']}"
    Dir.chdir(Rails.root.join("db")) do
      system "./generate_drops.sh | sqlplus #{Shellwords.shellescape(connect_string)}"
    end
  end

  desc "DANGER! Drops all user tables and sequences"
  task oracle_drop_severe: :environment do
    next unless db_allow_task?

    def purge(select)
      names = ActiveRecord::Base.connection.select_rows(select).map(&:first)
      names.each do |name|
        begin
          command = yield name
          puts command
          ActiveRecord::Base.connection.execute(command)
        rescue => e
          puts e.message
        end
      end
    end

    purge("select table_name from user_tables") do |table|
      "drop table #{table} cascade constraints purge"
    end

    purge("select sequence_name from user_sequences") do |sequence|
      "drop sequence #{sequence}"
    end

    purge("select view_name from user_views") do |view|
      "drop view #{view}"
    end

    purge("select index_name from user_indexes") do |index|
      "drop index #{index}"
    end

    purge("select type_name from user_types") do |type|
      "drop type #{type}"
    end

    ActiveRecord::Base.connection.execute("purge recyclebin")
  end

end

# frozen_string_literal: true

class MigrateRelays < ActiveRecord::Migration[4.2]

  def self.up
    Relay.reset_column_information

    Instrument.all.each do |inst|
      next if inst[:relay_type].blank? && inst[:relay_ip].blank? && inst[:relay_port].blank? && inst[:relay_username].blank? && inst[:relay_password].blank?

      relay_type = inst[:relay_type]
      relay_type = "RelaySynaccessRevA" if relay_type == "SynaccessRevA"

      begin
        relay_type.constantize.create!(
          instrument_id: inst.id,
          ip: inst[:relay_ip],
          port: inst[:relay_port],
          username: inst[:relay_username],
          password: inst[:relay_password],
          auto_logout: inst[:auto_logout],
          created_at: inst[:created_at],
          updated_at: inst[:updated_at],
        )
      rescue => e
        puts "Could not migrate Instrument with id #{inst.id}. #{e.message}"
      end
    end
  end

  def self.down
    Relay.all.each do |relay|
      relay.instrument.update_attributes!(
        relay_ip: relay.ip,
        relay_port: relay.port,
        relay_username: relay.username,
        relay_password: relay.password,
        relay_type: relay.type,
        auto_logout: relay.auto_logout,
      )

      relay.destroy
    end
  end

end

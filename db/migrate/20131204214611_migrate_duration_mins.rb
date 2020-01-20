# frozen_string_literal: true

class MigrateDurationMins < ActiveRecord::Migration[4.2]

  def up
    instrument_duration_mins.each do |instrument_id, duration_mins|
      Instrument.find(instrument_id).update_attribute :reserve_interval, duration_mins
    end
  end

  def down
    # because we can't restore the original values of products.reserve_interval
    raise ActiveRecord::IrreversibleMigration
  end

  def instrument_duration_mins
    idm = {}
    rs = ScheduleRule.select("instrument_id,duration_mins").group :instrument_id, :duration_mins

    rs.each do |r|
      if idm.key?(r.instrument_id) && idm[r.instrument_id] != r.duration_mins
        raise "ScheduleRule with instrument id #{r.instrument_id} has conflicting duration_mins (#{r.duration_mins}, #{idm[r.instrument_id]})!\n"
      end

      idm[r.instrument_id] = r.duration_mins
    end

    idm
  end

end

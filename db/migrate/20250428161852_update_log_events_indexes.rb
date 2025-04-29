# frozen_string_literal: true

class UpdateLogEventsIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index(
      :log_events,
      [:loggable_type, :event_type],
      name: "i_log_events_log_type_evnt_type",
    )
  end
end

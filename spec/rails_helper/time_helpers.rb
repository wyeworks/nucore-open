# frozen_string_literal: true

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.include TimeTravelHelpers

  config.before(:each) do
    next if self.class.metadata.slice(:time_travel, :skip_time_travel).values.any?

    # Because many specs rely on not crossing a fiscal year boundary we lock the
    # time globally. Rails's `travel_to` helper does not work well with nesting, so
    # we should use our own custom `travel_and_return` and `travel_to_and_return`
    # helpers. See TimeTravelHelpers. You can also use the spec_helper-defined
    # :time_travel metadata tag.
    travel_back
    now = (SettingsHelper.fiscal_year_beginning(Date.today) + 1.year + 10.days).change(hour: 9, min: 30)
    travel_to(now, safe: true)
  end

  config.around(:each, :time_travel) do |example|
    if defined?(now)
      # Roll back any record created in the let(:now) block
      ActiveRecord::Base.transaction do
        # Travel to a specific time if the spec defines let(:now)
        travel_to_and_return(now) { example.run }
        raise ActiveRecord::Rollback
      end
    else
      warn "Time travel filter requires `now` variable to be defined"
      example.run
    end
  end

  # Allow specififying a Timezone for a group of tests:
  # describe "in central", time_zone: "America/Chicago" do
  config.around(:each, :time_zone) do |example|
    Time.use_zone(example.metadata[:time_zone]) { example.call }
  end

  # TODO: This might be called by TimelineHelper tear down
  config.after(:each) { travel_back }
end

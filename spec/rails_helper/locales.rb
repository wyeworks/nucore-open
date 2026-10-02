# frozen_string_literal: true

require "text_helpers/rspec"

RSpec.configure do |config|
  config.include TextHelpers::RSpec::TestHelpers, locales: true

  config.before(:suite) do
    TextHelpers::RSpec.setup_spec_translations
  end

  config.after(:each, :locales) do
    TextHelpers::RSpec.reset_spec_translations
  end

  def facilities_route
    I18n.t("facilities_downcase")
  end
end

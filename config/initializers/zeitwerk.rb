Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "csv_helper" => "CSVHelper",
  )

  # Collapse external_services directory so classes don't need ExternalServices:: namespace
  autoloader.collapse("#{Rails.root}/app/models/external_services")
end

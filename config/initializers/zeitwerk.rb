Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "csv_helper" => "CSVHelper",
  )
end

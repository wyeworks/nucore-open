# frozen_string_literal: true

Ckeditor.setup do |config|
  # Ckeditor switched to a comercial license in v4.25
  # so we use a previous version
  #
  # //cdn.ckeditor.com/<version.number>/<distribution>/ckeditor.js
  config.cdn_url = "//cdn.ckeditor.com/4.19.1/standard/ckeditor.js"
end

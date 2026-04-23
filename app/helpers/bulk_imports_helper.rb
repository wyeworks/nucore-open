# frozen_string_literal: true

module BulkImportsHelper
  def import_type_label(import_type)
    I18n.t("bulk_imports.import_types.#{import_type}", default: import_type.humanize)
  end

  def bulk_import_required_headers(importer_class)
    return if importer_class.blank?

    importer_class.required_headers.map { |h| h.to_s.humanize }.join(", ")
  end
end

# frozen_string_literal: true

module BulkImportsHelper
  def import_type_label(import_type)
    I18n.t("bulk_imports.import_types.#{import_type}", default: import_type.humanize)
  end
end

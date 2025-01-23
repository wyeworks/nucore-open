# frozen_string_literal: true

module SangerSequencing

  class Primer < ApplicationRecord
    self.table_name = "sanger_sequencing_primers"

    belongs_to :sanger_product

    def self.default_list
      I18n.t("sanger_sequencing.primer.default_list")
    end

  end

end

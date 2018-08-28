# frozen_string_literal: true

module SangerSequencing

  class ProductGroup < ApplicationRecord

    # sanger_sequencing_product_groups is too long of a table name for Oracle
    self.table_name = "sanger_seq_product_groups"
    GROUPS = WellPlateConfiguration::CONFIGS.keys

    belongs_to :product

    validates :group, presence: true, inclusion: { in: GROUPS }
    validates :product, presence: true, uniqueness: true

  end

end

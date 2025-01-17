# frozen_string_literal: true

module SangerSequencing

  ##
  # Model that holds Sanger module configuration
  # for a product
  class SangerProduct < ApplicationRecord

    # sanger_sequencing_product_groups is too long of a table name for Oracle
    self.table_name = "sanger_seq_product_groups"
    GROUPS = WellPlateConfiguration::CONFIGS.keys
    DEFAULT_GROUP = 'default'

    belongs_to :product

    attribute :group, default: DEFAULT_GROUP

    validates :group, presence: true, inclusion: { in: GROUPS }
    validates :product, presence: true, uniqueness: { case_sensitive: false }

  end

end

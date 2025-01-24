# frozen_string_literal: true

module SangerSequencing

  ##
  # Model that holds Sanger module configuration
  # for a product
  class SangerProduct < ApplicationRecord

    # sanger_sequencing_product_groups is too long of a table name for Oracle
    self.table_name = "sanger_seq_product_groups"
    GROUPS = WellPlateConfiguration::CONFIGS.keys
    DEFAULT_GROUP = "default"

    belongs_to :product
    has_many :primers, class_name: "SangerSequencing::Primer"

    accepts_nested_attributes_for :primers, allow_destroy: true

    attribute :group, default: DEFAULT_GROUP

    validates :group, presence: true, inclusion: { in: GROUPS }
    validates :product, uniqueness: { case_sensitive: false }

    def self.by_group(group)
      where(group:)
    end

    def self.excluding_group(group)
      where.not(group:)
    end

    def create_default_primers
      primers.insert_all(Primer.default_list.map { |name| { name: } })
    end
  end

end

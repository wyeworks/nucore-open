# frozen_string_literal: true

module SangerSequencing

  module SangerEnabledFacility

    extend ActiveSupport::Concern

    included do
      has_many(
        :sanger_sequencing_primers,
        class_name: "SangerSequencing::Primer",
        inverse_of: :facility
      )

      accepts_nested_attributes_for :sanger_sequencing_primers
    end

  end

end

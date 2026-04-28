# frozen_string_literal: true

module SangerSequencing

  module LinkCollectionExtension

    extend ActiveSupport::Concern

    included do
      insert_index = tab_methods.index(:admin_facility) || -1
      tab_methods.insert(insert_index, :admin_sanger_sequencing)
    end

    def admin_sanger_sequencing
      if single_facility? && facility.sanger_sequencing_enabled?
        NavTab::Link.new(
          tab: :admin_sanger_sequencing,
          text: I18n.t("sanger_sequencing.name"),
          url: facility_sanger_sequencing_admin_submissions_path(facility),
        )
      end
    end

  end

end

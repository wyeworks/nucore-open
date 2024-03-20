# frozen_string_literal: true

module Projects

  module OrderDetailExtension

    extend ActiveSupport::Concern

    included do
      belongs_to :project,
                 class_name: "Projects::Project",
                 foreign_key: :project_id,
                 inverse_of: :order_details

      validate :project_must_be_active, if: :project_id_changed?

      delegate :projects, to: :facility, prefix: true
    end

    def selectable_projects
      (facility_projects.active.display_order + [project]).uniq.compact
    end

    private

    def project_must_be_active
      if project.present? && !project.active?
        errors.add(:project_id, :project_is_inactive)
      end
    end

  end

end

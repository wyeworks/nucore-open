module Projects

  module OrderRowImporterExtension

    def validate_custom_attributes
      if field(:project_name).present? && project.nil?
        add_error(:project_not_found)
      end
    end

    private

    def project
      facility.projects.active.find_by name: field(:project_name)
    end

    def custom_attributes
      { project_id: project&.id }
    end

  end

end

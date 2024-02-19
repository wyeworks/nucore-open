module Projects

  module OrderRowImporterExtension

    private

    def custom_attributes
      { project_id: field(:project_id) }
    end

  end

end

# frozen_string_literal: true

module Reports

  class GlobalUserRolesReport

    include Reports::CsvExporter

    attr_reader :users

    def initialize(users:)
      @users = users
    end

    def default_report_hash
      {
        name: :full_name,
        username: :username,
        email: :email,
        roles: :global_role_list,
      }
    end

    def report_data_query
      UserPresenter.wrap(users)
    end

    def filename
      "global_user_roles.csv"
    end

    def description
      "Global User Roles Report #{format_usa_datetime(Date.today)}"
    end

    protected

    def translation_scope
      "global_user_roles.index"
    end

  end

end

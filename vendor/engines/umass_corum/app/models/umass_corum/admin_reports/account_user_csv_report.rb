# frozen_string_literal: true

require "csv"

module UmassCorum

  module AdminReports

    # Data for all users payment source memberships
    class AccountUserCsvReport
      include DateHelper
      include TextHelpers::Translation
      include Rails.application.routes.url_helpers

      def to_csv
        CSV.generate do |csv|
          csv << headers
          AccountUser.all.each do |account_user|
            csv << build_row(account_user)
          end
        end
      end

      def filename
        "account_member_data.csv"
      end

      def description
        text(".subject")
      end

      def text_content
        text(".body")
      end

      def has_attachment?
        true
      end

      def translation_scope
        "views.umass_corum.admin_reports.account_users"
      end

      private

      def headers
        [
          text(".headers.username"),
          text(".headers.account_number"),
          text(".headers.account_url"),
          text(".headers.description"),
          text(".headers.type"),
          text(".headers.expiration"),
          text(".headers.suspended"),
          text(".headers.deleted"),
          text(".headers.account_role"),
          text(".headers.facilities"),
          text(".headers.full_name"),
          text(".headers.email"),
        ]
      end

      def build_row(account_user)
        account = account_user.account
        user = account_user.user
        [
          user.username,
          account.account_number,
          account_url(account),
          account.description,
          account.type_string,
          formatted_date(account.expires_at),
          formatted_date(account.suspended_at),
          formatted_date(account_user.deleted_at),
          account_user.user_role,
          account.facilities.map(&:name).join(";"),
          user.full_name,
          user.email,
        ]
      end

      def formatted_date(date)
        date.present? ? human_date(date) : ""
      end

      def account_url(account)
        return if account.nil?

        facility = if account.global?
                     Facility.cross_facility
                   else
                     account.facilities.first
                   end
        return if facility.nil?

        facility_account_path(facility, account)
      end

    end

  end

end

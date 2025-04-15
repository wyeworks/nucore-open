# frozen_string_literal: true

require "csv"

module UmassCorum

  module AdminReports

    # Data for all users
    class UserCsvReport
      include DateHelper
      include TextHelpers::Translation
      include Rails.application.routes.url_helpers

      def to_csv
        CSV.generate do |csv|
          csv << headers
          User.includes(:orders, :price_groups, :user_roles).find_each do |user|
            csv << build_row(user)
          end
        end
      end

      def filename
        "user_data.csv"
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
        "views.umass_corum.admin_reports.users"
      end

      private

      def headers
        [
          text(".headers.username"),
          text(".headers.profile_url"),
          text(".headers.created_at"),
          text(".headers.last_login"),
          text(".headers.last_order_activity"),
          text(".headers.first_name"),
          text(".headers.last_name"),
          text(".headers.certifications"),
          text(".headers.card_number"),
          text(".headers.iclass_number"),
          text(".headers.global_user_roles"),
          text(".headers.email"),
          text(".headers.phone"),
          text(".headers.internal_pricing"),
        ]
      end

      def build_row(user)
        [
          user.username,
          facility_user_path(facility, user),
          format_usa_datetime(user.created_at),
          format_usa_datetime(user.last_sign_in_at),
          last_order_activity(user),
          user.first_name,
          user.last_name,
          certs_for_user(user),
          user.card_number,
          user.i_class_number,
          UserPresenter.new(user).global_role_list,
          user.email,
          user.phone_number,
          user.internal? ? "Internal" : "External",
        ]
      end

      def facility
        @facility ||= Facility.cross_facility
      end

      # The goal here is a high-level metric for user activity.
      # This might be an unpurchased order (still in cart),
      # an "on-behalf-of" order (placed for the user by an admin),
      # and may not be the actual purchase date.
      def last_order_activity(user)
        format_usa_datetime(user.orders.last&.created_at)
      end

      def certs_for_user(user)
        certs = cert_lookup_for_user(user).map { |cert, user_certified| cert.name if user_certified }
        certs.compact.join(";")
      rescue Net::OpenTimeout
        "OWL Timeout"
      end

      # Returns a Hash
      # Keys are ResearchSafetyCertificate objects
      # Values are booleans representing whether the user is certified
      def cert_lookup_for_user(user)
        ResearchSafetyCertificationLookup.certificates_with_status_for(user)
      end

    end

  end

end

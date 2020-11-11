# frozen_string_literal: true

module LdapAuthentication

  class UserEntry

    attr_reader :ldap_entry

    CONVERTABLE_ATTRIBUTES = [:username, :first_name, :last_name, :email].freeze

    # Returns an Array of `LdapAuthentication::UserEntry`s
    def self.search(uid)
      return [] unless uid

      ldap_entries = nil
      ActiveSupport::Notifications.instrument "search.ldap_authentication" do |payload|
        ldap_entries = with_retry { admin_ldap.search(filter: Net::LDAP::Filter.eq(LdapAuthentication.username_attribute, uid)) }
        payload[:uid] = uid
        payload[:results] = ldap_entries
      end

      ldap_entries.map { |entry| new(entry) }
    end

    # Returns a single LdapAuthentication::UserEntry
    def self.find(uid)
      search(uid).first
    end

    def self.admin_ldap
      LdapAuthentication.admin_connection
    end
    private_class_method :admin_ldap

    def initialize(ldap_entry)
      @ldap_entry = ldap_entry
    end

    def username
      ldap_entry.public_send(LdapAuthentication.username_attribute).last
    end

    def first_name
      ldap_entry.givenname.first
    end

    def last_name
      ldap_entry.sn.first
    end

    def email
      ldap_entry.mail.first
    end

    def to_user
      ::User.new(attributes)
    end

    def attributes
      (CONVERTABLE_ATTRIBUTES + additional_attributes).each_with_object({}) do |field, output|
        field_value = self.public_send(field).presence
        output[field] = field_value if field_value
      end
    end

    def additional_attributes
      LdapAuthentication.additional_user_attributes.map(&:to_sym)
    end

    def self.with_retry(max_attempts = 3)
      tries = 0
      begin
        yield
      rescue Net::LDAP::Error => e
        tries += 1
        tries >= max_attempts ? raise : retry
      end
    end

  end

end

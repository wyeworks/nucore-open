# frozen_string_literal: true

require "devise_ldap_authenticatable"
require "ldap_authentication/user_entry"
require "ldap_authentication/null_connection"
require "ldap_authentication/engine"

module LdapAuthentication

  def self.configured?
    config.present?
  end

  def self.config
    return @config if defined?(@config)

    if Rails.env.test?
      @admin_connection = NullConnection.new
      @config = {}
    elsif File.exist?(Rails.root.join("config", "ldap.yml"))
      @config = load_config_from_file
      raise "Could not configure LDAP. Check your config/ldap.yml file." if @config.blank?
    else
      @config = {}
    end

    @config["encryption"] = encryption_method if encryption_method.present?

    @config
  end

  def self.admin_connection
    @admin_connection ||= Devise::LDAP::Connection.admin
  end

  def self.username_attribute
    config.fetch("username_attribute", "uid")
  end

  def self.additional_user_attributes
    config.fetch("additional_user_attributes", [])
  end

  # Additional encryption method options.
  # Can be either "simple_tls" or "start_tls"
  # See https://github.com/ruby-ldap/ruby-net-ldap/blob/master/lib/net/ldap.rb#L483
  # and https://github.com/ruby-ldap/ruby-net-ldap/blob/master/lib/net/ldap.rb#L1341
  #
  # NOTE:
  # If you need to pass in additional tls_options, you can override this method so that
  # instead of reading from ldap.yml, it will return something like:
  # { method: :start_tls, tls_options: OpenSSL::SSL::SSLContext::DEFAULT_PARAMS }
  def self.encryption_method
    config.fetch("encryption_method", "")
  end

  def self.load_config_from_file
    config_file_path = Rails.root.join("config", "ldap.yml")
    parsed = ERB.new(File.read(config_file_path)).result
    yaml = YAML.safe_load(parsed, permitted_classes: [], permitted_symbols: [], aliases: true) || {}
    yaml.fetch(Rails.env, {})
  end

end

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

  def self.load_config_from_file
    config_file_path = Rails.root.join("config", "ldap.yml")
    parsed = ERB.new(File.read(config_file_path)).result
    # safe_load(yaml, whitelist_classes, whitelist_symbols, allow_aliases)
    yaml = YAML.safe_load(parsed, [], [], true) || {}
    yaml.fetch(Rails.env, {})
  end

end

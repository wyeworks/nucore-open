# frozen_string_literal: true

if defined?(ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter)
  ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter.class_eval do
    # The default in the adapter is 10000, but to start with 1 like other adapters
    # do we reset it. See https://github.com/rsim/oracle-enhanced/issues/1595
    # It is changed to 1 by default in the version of the adapter targeted at Rails 6
    # https://github.com/rsim/oracle-enhanced/pull/1636
    self.default_sequence_start_value = 1

    # Without this, we get an error "Combination of limit and lock is not supported"
    # whenever we use find_or_create_by.
    # https://github.com/rsim/oracle-enhanced/issues/920
    self.use_old_oracle_visitor = true
  end

  # OCI8 does not realize that SafeBuffer is a type of string, so we need to
  # tell it what to do.
  OCI8::BindType::Mapping["ActiveSupport::SafeBuffer"] = OCI8::BindType::String
end

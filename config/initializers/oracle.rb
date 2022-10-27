# frozen_string_literal: true

if defined?(ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter)
  ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter.class_eval do

    # The following patched methods address issues with thread safety in specs:
    # RuntimeError: executing in another thread
    # see https://github.com/rsim/oracle-enhanced/pull/2287
    # Hopefully this gets fixed upstream at some point
    def prefetch_primary_key_with_lock?(table_name = nil)
      @lock.synchronize do
        prefetch_primary_key_without_lock?(table_name)
      end
    end
    alias_method :prefetch_primary_key_without_lock?, :prefetch_primary_key?
    alias_method :prefetch_primary_key?, :prefetch_primary_key_with_lock?

    def column_definitions_with_lock(table_name = nil)
      @lock.synchronize do
        column_definitions_without_lock(table_name)
      end
    end
    alias_method :column_definitions_without_lock, :column_definitions
    alias_method :column_definitions, :column_definitions_with_lock

    def pk_and_sequence_for_with_lock(table_name, owner = nil, desc_table_name = nil)
      @lock.synchronize do
        pk_and_sequence_for_without_lock(table_name, owner, desc_table_name)
      end
    end
    alias_method :pk_and_sequence_for_without_lock, :pk_and_sequence_for
    alias_method :pk_and_sequence_for, :pk_and_sequence_for_with_lock

    def primary_keys_with_lock(table_name)
      @lock.synchronize do
        primary_keys_without_lock(table_name)
      end
    end
    alias_method :primary_keys_without_lock, :primary_keys
    alias_method :primary_keys, :primary_keys_with_lock

  end

  # OCI8 does not realize that SafeBuffer is a type of string, so we need to
  # tell it what to do.
  OCI8::BindType::Mapping["ActiveSupport::SafeBuffer"] = OCI8::BindType::String
end

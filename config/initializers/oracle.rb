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

# TODO - Remove patch after upgrading to rails 6.1
# Jason's fix didn't make it into 6.0
# https://githubmemory.com/repo/rsim/oracle-enhanced/issues/1985
# https://github.com/rsim/oracle-enhanced/commit/b88deba791f0e00b6ab0f252cb3662aaa9536465
# https://github.com/jhanggi/oracle-enhanced/pull/1
if defined?(ActiveRecord::ConnectionAdapters::OracleEnhanced::SchemaDumper)
  ActiveRecord::ConnectionAdapters::OracleEnhanced::SchemaDumper.class_eval do
    def _indexes(table, stream)
      if (indexes = @connection.indexes(table)).any?
        add_index_statements = indexes.map do |index|
          case index.type
          when nil
            # do nothing here. see indexes_in_create
            statement_parts = []
          when "CTXSYS.CONTEXT"
            if index.statement_parameters
              statement_parts = [ ("add_context_index " + remove_prefix_and_suffix(table).inspect) ]
              statement_parts << index.statement_parameters
            else
              statement_parts = [ ("add_context_index " + remove_prefix_and_suffix(table).inspect) ]
              statement_parts << index.columns.inspect
              statement_parts << ("sync: " + $1.inspect) if index.parameters =~ /SYNC\((.*?)\)/
              statement_parts << ("name: " + index.name.inspect)
            end
          else
            # unrecognized index type
            statement_parts = ["# unrecognized index #{index.name.inspect} with type #{index.type.inspect}"]
          end
          "  " + statement_parts.join(", ") unless statement_parts.empty?
        end.compact

        return if add_index_statements.empty?

        stream.puts add_index_statements.sort.join("\n")
        stream.puts
      end
    end

    def indexes_in_create(table, stream)
      if (indexes = @connection.indexes(table)).any?
        index_statements = indexes.map do |index|
          "    t.index #{index_parts(index).join(', ')}" unless index.type == "CTXSYS.CONTEXT"
        end
        stream.puts index_statements.compact.sort.join("\n")
      end
    end
  end
end

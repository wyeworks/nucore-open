module UmassCorum

  class JournalWriter

    def initialize(headers: {})
      @headers = headers
      @row_data = []
    end

    def header_row
      format_row(@headers, JournalDefinition::HEADER)
    end

    def <<(row)
      @row_data << row
    end

    def concat(other)
      @row_data.concat(other)
    end

    def rows
      @rows ||= @row_data.lazy.map do |row|
        format_row(row, JournalDefinition::BODY)
      end
    end

    def to_s
      to_a.join("\n")
    end

    def to_a
      [header_row] + rows.to_a
    end

    private

    def format_row(row, definition)
      definition.map do |c|
        format_data(row[c.name], c)
      end.pack(definition.map { |c| "A#{c.width}"}.join)
    end

    def format_data(data, column)
      return data unless column.options
      return nil unless data

      case column.options[:type]
      when :date
        data.strftime("%m%d%Y")
      when :integer
        format("%0#{column.width}d", data)
      when :decimal
        format("%0#{column.width}d", data * 100)
      else
        data
      end
    end

  end

end

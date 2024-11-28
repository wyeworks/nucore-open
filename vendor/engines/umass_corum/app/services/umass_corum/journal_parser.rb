module UmassCorum

  class JournalParser

    include Enumerable

    def initialize(string)
      @rows = string.lines
    end

    def self.parse(string)
      new(string)
    end

    def header
      @header ||= parse_row(@rows.first, JournalDefinition::HEADER)
    end

    def each
      @rows.drop(1).each do |row|
        yield parse_row(row, JournalDefinition::BODY)
      end
    end

    private

    def parse_row(row, definition)
      format = definition.map { |c| "A#{c.width}" }.join
      result = {}
      definition.zip(row.unpack(format)).each do |c, data|
        result[c.name] = convert(data.strip, c.options)
      end
      result
    end

    def convert(data, options)
      return data unless options && options[:type]

      case options[:type]
      when :date
        Date.strptime(data, "%m%d%Y")
      when :integer
        Integer(data, 10)
      when :decimal
        BigDecimal(data) / BigDecimal(100)
      else
        data
      end
    end

  end

end

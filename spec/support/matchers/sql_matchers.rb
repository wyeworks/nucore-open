# frozen_string_literal: true

if Nucore::Database.oracle?

  def timestamp_pattern(field, operator, time)
    timestamp = time.utc.strftime("%Y-%m-%d\\s%H:%M:%S")

    /
      \b
      #{field}
      \s
      #{operator}
      \s
      TO_TIMESTAMP\('#{timestamp}:\d{6}','YYYY-MM-DD\sHH24:MI:SS:FF6'\)
    /x
  end

  RSpec::Matchers.define :contain_beginning_of_day do |field, datetime|
    match do |actual|
      actual.to_sql =~ timestamp_pattern(field, ">=", datetime.beginning_of_day)
    end
  end

  RSpec::Matchers.define :contain_end_of_day do |field, datetime|
    match do |actual|
      actual.to_sql =~ timestamp_pattern(field, "<=", datetime.end_of_day)
    end
  end

  RSpec::Matchers.define :contain_string_in_sql do |expected|
    expected = expected.tr("\`", "\"").upcase
    match do |actual|
      actual.to_sql.upcase.include? expected
    end
    failure_message do |actual|
      "expected that #{actual.to_sql.upcase} would include #{expected}"
    end

    failure_message_when_negated do |actual|
      "expected that #{actual.to_sql.upcase} would not include #{expected}"
    end
  end

else

  RSpec::Matchers.define :contain_end_of_day do |field, datetime|
    expected = /\A#{field} <= '#{datetime.end_of_day.utc.strftime('%Y-%m-%d %H:%M:%S')}(\.9+)?'\z/
    match do |actual|
      actual.where_values.any? do |where_value|
        where_value =~ expected
      end
    end
  end

  RSpec::Matchers.define :contain_beginning_of_day do |field, datetime|
    expected = /\A#{field} >= '#{datetime.beginning_of_day.utc.strftime('%Y-%m-%d %H:%M:%S')}(\.0+)?'\z/
    match do |actual|
      actual.where_values.any? do |where_value|
        where_value =~ expected
      end
    end
  end

  RSpec::Matchers.define :contain_string_in_sql do |expected|
    match do |actual|
      actual.to_sql.include? expected
    end

    failure_message do |actual|
      "Expected: #{actual.to_sql}\n To Contain: #{expected}"
    end
  end
end

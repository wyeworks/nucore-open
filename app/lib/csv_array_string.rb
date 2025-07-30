# frozen_string_literal: true

# Takes a string that is a comma-separated list
# the #to_a and any Enumerable methods will run only
# over values that exist.
# CsvArrayString.new("test, test2, ,, test3").to_a
#   => ["test", "test2", "test3"]
class CsvArrayString < SimpleDelegator

  include Enumerable

  delegate :each, to: :to_a

  def to_a
    __getobj__.to_s.split(",").select(&:present?).map(&:strip)
  end
  alias to_ary to_a

  def to_s
    to_a.join(", ")
  end

end

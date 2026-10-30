# frozen_string_literal: true

module AZHelper
  # Generates empty hash with keys for each letter
  ALPHABET = ("A".."Z").to_a.map { |x| [x, []] }.to_h
  def build_az_list(facilities)
    ALPHABET.merge(facilities.group_by { |row| row.name[0].upcase })
  end

  def az_classname_for_facility(index, _letter)
    "js--azlist#{index}"
  end
end

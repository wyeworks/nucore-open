# frozen_string_literal: true

class WhitespaceNormalizer
  def self.normalize(text)
    text
      &.gsub(/\p{Blank}/, " ") # spaces including unicode
      &.gsub(/\R+/, "\n") # newlines
  end
end

# frozen_string_literal: true

module SearchHelper

  def generate_multipart_like_search_term(raw_term)
    term = (raw_term || "").strip
    term.tr_s! " ", "%"
    term = "%" + term + "%"
    term.downcase
  end

end

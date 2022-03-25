# frozen_string_literal: true

module HashHelper

  # Inserts one hash into another after it finds a specific key
  # original_hash = { a: 1, b: 2, c: 3, d: 4 }
  # additions = { e: 5, f: 6 }
  # insert_into_hash_after(original_hash, :c, additions)
  # => { a: 1, b: 2, c: 3, e: 5, f: 6, d: 4 }
  def insert_into_hash_after(original_hash, after_column, additions)
    original_hash.each_with_object({}) do |(k, v), new_hash|
      new_hash[k] = v
      new_hash.merge!(additions) if k == after_column
    end
  end

end

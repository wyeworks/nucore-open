# frozen_string_literal: true

module ArrayUtil

  def self.insert_before(array, new_element, element)
    idx = array.index(element) || -1
    array.insert(idx, new_element)
  end

  def self.insert_after(array, new_element, element)
    idx = array.index(element) || -2
    array.insert(idx + 1, new_element)
  end

end

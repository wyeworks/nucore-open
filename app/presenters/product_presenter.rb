# frozen_string_literal: true

class ProductPresenter < SimpleDelegator

  def to_s
    tags = []
    tags << :hidden if is_hidden?
    tags << :archived if is_archived?

    ([name] + tags.map { |t| I18n.t(t, scope: "products.tags") }).join(" ")
  end

end

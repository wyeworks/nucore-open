# frozen_string_literal: true

module Users

  class DefaultPriceGroupSelector

    def call(user)
      user.authenticated_locally? ? PriceGroup.external : PriceGroup.base
    end

  end

end

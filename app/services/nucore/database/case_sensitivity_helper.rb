# frozen_string_literal: true

module Nucore

  module Database

    module CaseSensitivityHelper

      def insensitive_where(relation, column, value)
        relation.where("UPPER(#{column}) = UPPER(?)", value)
      end

    end

  end

end

# frozen_string_literal: true

module GlobalSearch
  class Base
    attr_reader :facility, :query, :user

    def initialize(user = nil, facility = nil, query = nil)
      @user = user
      @facility = facility
      @query = query.to_s.strip
    end

    def results
      @results ||= query.present? ? restrict(search) : []
    end

    private

    def restrict(items)
      items.select { |item| Ability.new(user, item).can?(:show, item) }
    end
  end
end

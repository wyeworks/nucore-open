# frozen_string_literal: true

module UmassCorum

  module GlobalSearch

    class JournalSearcher < ::GlobalSearch::Base

      def template
        "journals"
      end

      private

      def query_object
        if facility.try(:single_facility?)
          facility.journals
        else
          Journal
        end
      end

      def restrict(journals)
        journals.select do |journal|
          Ability.new(user, journal).can?(:show, journal)
        end
      end

      def search
        query_object.where(als_number: query).or(query_object.where("lower(reference) LIKE ?", "%#{query.downcase}%"))
      end

    end

  end

end

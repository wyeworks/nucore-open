# frozen_string_literal: true

module DateTimeInput

  module Model

    extend ActiveSupport::Concern

    module ClassMethods

      def date_time_inputable(attribute)
        define_method("#{attribute}=") do |input|
          if input.is_a?(Hash)
            super(FormData.from_param(input).to_time)
          else
            super(input)
          end
        end

        define_method("#{attribute}_date_time_data") do
          FormData.new(public_send(attribute))
        end
      end

    end

  end

end

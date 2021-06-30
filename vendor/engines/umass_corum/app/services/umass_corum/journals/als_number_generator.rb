module UmassCorum

  module Journals
    
    class AlsNumberGenerator
      
      MAX_VALUE = 999

      class AlsNumberError < NUCore::Error; end

      def self.next_als
        raise AlsNumberError, "ALS sequence has hit the max allowed value - please reset it before trying again" if max_als_number == MAX_VALUE

        max_als_number.to_i + 1
      end

      private

      def self.max_als_number
        Journal.maximum(:als_number).presence || 0
      end
    end

  end

end

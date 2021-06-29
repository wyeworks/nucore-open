module UmassCorum

  module Journals
    
    class AlsNumberGenerator
      
      MAX_VALUE = 999

      class AlsNumberError < NUCore::Error; end

      def self.next_als
        raise AlsNumberError, "ALS sequence has hit the max allowed value - please reset it before trying again" if AlsSequenceNumber.maximum(:id) == MAX_VALUE

        seq_next = AlsSequenceNumber.create
        "ALS#{format('%03d', seq_next.id)}"
      end

      private
      
      class AlsSequenceNumber < ActiveRecord::Base
      end
    end

  end

end
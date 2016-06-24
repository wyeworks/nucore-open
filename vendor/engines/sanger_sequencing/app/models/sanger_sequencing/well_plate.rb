module SangerSequencing

  class WellPlate
    # Mapping is a cell to a sample id
    # e.g. { "A01" => nil, "B01" => 12345 }
    def initialize(mapping, samples: nil)
      @mapping = mapping
      @samples = samples
    end

    delegate :[], to: :cells

    def cells
      return @cells if @cells

      @cells = @mapping.each_with_object({}) do |(cell, id), results|
        results[cell] = case id
        when "reserved"
          ReservedSample.new
        when ""
          BlankSample.new
        else
          @samples ? @samples.find { |s| s.id.to_i == id.to_i } : Sample.find(id)
        end
      end
    end

    private

    class ReservedSample
      attr_accessor :id

      def reserved?
        true
      end

      def customer_sample_id
        "Control"
      end
    end

    class BlankSample
      attr_accessor :id

      def reserved?
        false
      end

      def customer_sample_id
        ""
      end
    end

  end

end

# frozen_string_literal: true

class QuantityPresenter

  QuantityDisplay = Struct.new(:value) do
    def html
      to_s
    end

    delegate :to_s, to: :value

    def csv
      value.to_s
    end
  end

  TimeQuantityDisplay = Struct.new(:value) do
    include ActionView::Helpers::TagHelper

    def csv
      # equal sign and quotes prevent Excel from formatting as a date/time
      %(="#{MinutesToTimeFormatter.new(value)}")
    end

    def to_s
      MinutesToTimeFormatter.new(value).to_s
    end

    def html
      to_s
    end
  end

  DayQuantityDisplay = Struct.new(:value) do
    include ActionView::Helpers::TagHelper

    def csv
      # equal sign and quotes prevent Excel from formatting as a date/time
      %(="#{value}")
    end

    delegate :to_s, to: :value

    def html
      to_s
    end
  end

  delegate :to_s, :csv, :html, to: :display

  def initialize(product, quantity)
    @product = product
    @quantity = quantity
  end

  private

  def display
    @display ||= if @product.try(:daily_booking?)
                   DayQuantityDisplay.new(@quantity)
                 elsif @product.quantity_as_time?
                   TimeQuantityDisplay.new(@quantity)
                 else
                   QuantityDisplay.new(@quantity)
                 end
  end

end

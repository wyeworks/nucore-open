# frozen_string_literal: true

module SplitAccounts
  class SplitTimeDataDecorator < SimpleDelegator
    attr_accessor :quantity
    attr_writer :actual_duration_mins

    def duration_mins
      __getobj__.instance_variable_get(:@duration_mins)
    end

    def actual_duration_mins
      @actual_duration_mins || super
    end

    # Let it pretend to be a real Reservation
    def is_a?(klass)
      __getobj__.class.object_id == klass.object_id
    end

    def self.primary_key
      __getobj__.class.primary_key
    end
  end
end

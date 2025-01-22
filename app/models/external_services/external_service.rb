# frozen_string_literal: true

#
# Represents a 3rd party service in use by the system
class ExternalService < ApplicationRecord
  validates_presence_of :location

  def self.matching_location(value)
    where("location like ?", "%#{value}%")
  end
end

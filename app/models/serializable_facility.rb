# frozen_string_literal: true

class SerializableFacility < SimpleDelegator
  include GlobalID::Identification

  def id
    super || "cross_facility"
  end

  def self.find(id)
    if id == "cross_facility"
      Facility.cross_facility
    else
      Facility.find(id)
    end
  end
end

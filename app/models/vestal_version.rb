# frozen_string_literal: true

# This is a _temporary_ class to make up for the fact that the
# vestal versions gem is no longer in the project. It's here to
# allow access to the vestal data.
# once that data is no longer needed, this class can be removed
# along with the has_many clause in OrderDetail

class VestalVersion < ApplicationRecord

  belongs_to :versioned, polymorphic: true

  serialize :modifications, coder: JSON

end

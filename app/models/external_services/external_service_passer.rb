# frozen_string_literal: true

#
# A polymorphic join class between an +ExternalService+
# and a class that passes off work to that service
# (the passer).
class ExternalServicePasser < ApplicationRecord
  belongs_to :external_service
  belongs_to :passer, polymorphic: true

  validates :external_service_id, :passer_id, presence: true

  scope :actives, -> { where(active: true) }
end

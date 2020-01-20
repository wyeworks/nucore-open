# frozen_string_literal: true

class SecureRoom < Product

  include Products::ScheduleRuleSupport

  has_many :card_readers, foreign_key: :product_id, class_name: "SecureRooms::CardReader"
  has_many :events, foreign_key: :product_id, class_name: "SecureRooms::Event"
  has_many :occupancies, foreign_key: :product_id, class_name: "SecureRooms::Occupancy"
  belongs_to :facility

  before_validation :set_secure_room_defaults, on: :create
  validates :dashboard_token, presence: true

  def time_data_field
    :occupancy
  end

  def entry_only?
    card_readers.egress.none?
  end

  private

  def set_secure_room_defaults
    self.requires_approval = true
    self.is_hidden = true
    self.dashboard_token = SecureRandom.uuid
  end

end

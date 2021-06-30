# frozen_string_literal: true

class OfflineReservation < Reservation

  CATEGORIES = I18n.t("offline_reservations.categories").keys.map(&:to_s).freeze

  validates :admin_note, presence: true
  validates :category, presence: true
  validates :category,
            inclusion: { in: CATEGORIES, allow_blank: false }

  belongs_to :product

  scope :current, -> { where(reserve_end_at: nil).where("reserve_start_at < ?", Time.current) }

  def display_user
    created_by
  end

  def admin?
    true
  end

  def admin_removable?
    false
  end

  def end_at_required?
    false
  end

  def to_s
    if reserve_end_at.present?
      super
    else
      "#{I18n.l(reserve_start_at)} -"
    end
  end

  private

  def set_billable_minutes
    self.billable_minutes = nil
  end

end

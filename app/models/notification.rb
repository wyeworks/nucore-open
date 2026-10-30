# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :subject, polymorphic: true

  validates_presence_of :user_id, :subject_id, :notice

  scope :about, ->(subject) { where(subject_id: subject.id, subject_type: subject.class.name) }
  scope :active, -> { where(dismissed_at: nil) }

  def notice
    self[:notice].try(:html_safe)
  end

  def self.create_for!(user, subject)
    create!(
      user:,
      subject:,
      notice: subject.to_notice(self, user),
    )
  end
end

# frozen_string_literal: true

class Affiliate < ApplicationRecord

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  scope :destroyable, -> { where.not(id: self.OTHER.id) }
  scope :alphabetical, -> { order(:name) }

  # rubocop:disable Naming/MethodName, Naming/MemoizedInstanceVariableName
  def self.OTHER
    @other ||= find_or_create_by(name: "Other") { |a| a.subaffiliates_enabled = true }
  end
  # rubocop:enable Naming/MethodName, Naming/MemoizedInstanceVariableName

  before_destroy { throw :abort if other? }

  def other?
    self == self.class.OTHER
  end

end

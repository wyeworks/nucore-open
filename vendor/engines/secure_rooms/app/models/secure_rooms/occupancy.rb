# frozen_string_literal: true

module SecureRooms

  class Occupancy < ApplicationRecord

    include DateTimeInput::Model

    belongs_to :secure_room, foreign_key: :product_id
    belongs_to :user
    belongs_to :account
    belongs_to :order_detail
    belongs_to :entry_event, class_name: "SecureRooms::Event"
    belongs_to :exit_event, class_name: "SecureRooms::Event"

    delegate :facility, to: :secure_room
    delegate :to_s, to: :range
    delegate :editing_time_data, to: :order_detail, allow_nil: true

    date_time_inputable :entry_at
    date_time_inputable :exit_at

    alias_attribute :actual_start_at, :entry_at
    alias_attribute :actual_end_at, :exit_at

    validates :secure_room, :user, presence: true
    validate :entry_and_exit_are_valid, if: :editing_time_data

    # Not used internally, but implemented for API compatibility with Reservation
    attr_writer :force_completion

    def self.valid
      where(orphaned_at: nil)
    end

    def self.orphaned
      where.not(orphaned_at: nil)
    end

    def self.current
      valid.order(entry_at: :desc).where(exit_at: nil).where.not(entry_at: nil)
    end

    def self.recent
      valid.order(exit_at: :desc).where.not(exit_at: nil).limit(10)
    end

    def mark_orphaned!
      update!(orphaned_at: Time.current)
    end

    def orphan?
      orphaned_at?
    end

    def associate_entry!(event)
      update!(
        entry_event: event,
        entry_at: event.occurred_at,
      )
      self
    end

    def associate_exit!(event)
      update!(
        exit_event: event,
        exit_at: event.occurred_at,
      )
      self
    end

    def order_completable?
      activity_finalized = orphaned_at? || (entry_at && exit_at)
      order_detail_id? && account_id? && activity_finalized
    end

    def actual_duration_mins
      range.duration_mins
    end

    def problem_description_key
      if entry_at.blank?
        :missing_entry
      elsif exit_at.blank?
        :missing_exit
      end
    end

    def force_dirty!
      # This doesn't have to be entry_at -- it just needs to be something
      entry_at_will_change!
    end

    private

    def range
      TimeRange.new(entry_at, exit_at)
    end

    def entry_and_exit_are_valid
      if entry_at && exit_at
        errors.add(:actual_duration_mins, :zero_minutes) if exit_at <= entry_at
      elsif entry_at.blank?
        errors.add(:entry_at, :blank)
      elsif exit_at.blank?
        errors.add(:exit_at, :blank)
      end
    end

  end

end

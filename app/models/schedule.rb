# frozen_string_literal: true

class Schedule < ApplicationRecord

  include Nucore::Database::SortHelper

  belongs_to :facility

  scope :positioned, -> { order_by_asc_nulls_last(:position) }

  with_options class_name: "Instrument" do |schedule|
    schedule.has_many :facility_instruments, -> { not_archived }
    schedule.has_many :products
    schedule.has_many :public_instruments, -> { active }
  end

  with_options through: :products do |schedule|
    schedule.has_many :admin_reservations
    schedule.has_many :reservations
  end

  validates_presence_of :facility

  scope :active, -> { where(id: Instrument.not_archived.with_schedule.select(:schedule_id)) }

  def shared?
    products.count > 1
  end

  def display_name
    key = "instruments.instrument_fields.schedule.#{shared? ? 'shared' : 'unshared'}"
    "#{I18n.t(key)}: #{name}"
  end

  def display_order_name
    shared? ? display_name : name
  end

end

# frozen_string_literal: true

class ProductAccessGroup < ApplicationRecord

  belongs_to :product
  has_many :product_users, dependent: :nullify
  has_many :users, through: :product_users

  # oracle has a maximum table name length of 30, so we have to abbreviate it down
  has_and_belongs_to_many :schedule_rules, join_table: "product_access_schedule_rules"

  validates :product, presence: true
  validates :name, presence: true, uniqueness: { scope: :product_id, case_sensitive: false }

  def to_s
    name
  end

end

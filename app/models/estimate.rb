# frozen_string_literal: true

class Estimate < ApplicationRecord
  belongs_to :facility, inverse_of: :estimates
  belongs_to :user
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by_id

end

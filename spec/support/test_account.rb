# frozen_string_literal: true

class TestAccount < Account
  before_validation :set_expires_at

  private

  def set_expires_at
    self.expires_at ||= 1.year.from_now
  end
end

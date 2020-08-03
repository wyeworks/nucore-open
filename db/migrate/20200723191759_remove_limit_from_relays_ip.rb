# frozen_string_literal: true

class RemoveLimitFromRelaysIp < ActiveRecord::Migration[5.2]
  def up
    change_column :relays, :ip, :string, limit: nil
  end

  def down
    change_column :relays, :ip, :string, limit: 15
  end
end

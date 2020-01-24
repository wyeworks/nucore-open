# frozen_string_literal: true

class ConvertExternalServiceReceiverData < ActiveRecord::Migration[4.2]

  def up
    ExternalServiceReceiver.find_each do |receiver|
      show_url = receiver.response_data
      new_data = { show_url: show_url, edit_url: "#{show_url}/take" }
      receiver.update_attribute :response_data, new_data.to_json
    end
  end

  def down
    ExternalServiceReceiver.find_each do |receiver|
      json = receiver.response_data
      parsed = JSON.parse json
      receiver.update_attribute :response_data, parsed[:show_url]
    end
  end

end

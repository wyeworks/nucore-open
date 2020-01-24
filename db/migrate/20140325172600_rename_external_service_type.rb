# frozen_string_literal: true

class RenameExternalServiceType < ActiveRecord::Migration[4.2]

  def up
    ExternalService.where(type: "Surveyor").update_all type: UrlService.name
  end

  def down
    ExternalService.where(type: UrlService.name).update_all type: "Surveyor"
  end

end

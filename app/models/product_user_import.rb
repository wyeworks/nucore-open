# frozen_string_literal: true

require "csv"

class ProductUserImport < ApplicationRecord

  include DownloadableFile

  belongs_to :product
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id

  validates_presence_of :file, :creator

  attr_accessor :successes, :failures, :skipped

  def process_upload!
    self.successes = []
    self.skipped = []
    self.failures = []

    if parsed_import_file.headers.include?("Username")
      ProductUser.transaction do
        parsed_import_file.each { |row| import_row(row) }
        raise ActiveRecord::Rollback if failed?
      end

      self.processed_at = Time.zone.now
    else
      failures << "Uploaded CSV file must include a 'Username' column.  Please try again."
    end


    if new_product_users_added?
      save!
      successes.map! do |product_user|
        LogEvent.log(product_user, :create, creator)
        "* #{product_user.user.username}\n"
      end
    end
  end

  def failed?
    failures.count > 0
  end

  def new_product_users_added?
    successes.count > 0 && !failed?
  end

  private

  def import_row(row)
    row_username = row["Username"]
    user = User.find_by(username: row_username)
    new_product_user = ProductUserCreator.create(user: user, product: product, approver: creator)

    if new_product_user.persisted?
      successes << new_product_user
    elsif new_product_user.errors.full_messages.to_sentence == "User is already approved"
      skipped << "* #{row_username}\n"
    else
      failures << "* #{row_username}: #{new_product_user.errors.full_messages.to_sentence}\n"
    end
  rescue => e
    failures << "* #{row_username}: #{e.message}\n"
  end

  def parsed_import_file
    @parsed_import_file ||=
      CSV.parse(read_attached_file, headers: true, skip_lines: /^,*$/)
  end

end

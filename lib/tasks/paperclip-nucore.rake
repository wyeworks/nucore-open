# frozen_string_literal: true

namespace :paperclip do
  def move_record(new_class, old_record)
    new_record = new_class.find(old_record.id)
    new_record.file = old_record.file
    # Journals have some validations on update that would fail here
    new_record.save!(validate: false)
    old_record.file.destroy
  rescue Errno::ENOENT => e
    puts "ERROR: #{e}"
  end

  # How to use:
  # Change the path in `OldJournal` and `OldStoredFile` below to the old path format (what's currently in
  # settings.yml or the environment's settings). Note: if you have :class in there, you'll
  # need to replace that with `journals` or `stored_files`.
  # Update the `paperclip.path` in settings.yml to your new destination
  # Run this script `bundle exec rake paperclip:migrate_path:all`
  namespace :migrate_path do
    desc "Migrate paperclip path format"
    task all: [:journals, :stored_files]

    task journals: :environment do
      class OldJournal < ApplicationRecord
        self.table_name = "journals"
        has_attached_file :file, PaperclipSettings.config.merge(path: ":rails_root/public/:attachment/:id_partition/:style/:safe_filename")
      end

      OldJournal.find_each do |old_record|
        move_record(Journal, old_record)
      end
    end

    task stored_files: :environment do
      class OldStoredFiles < ApplicationRecord
        self.table_name = "stored_files"
        has_attached_file :file, PaperclipSettings.config.merge(path: ":rails_root/public/:attachment/:id_partition/:style/:safe_filename")
      end
      OldStoredFiles.find_each do |old_record|
        move_record(StoredFile, old_record)
      end
    end
  end

  namespace :mime do
    desc "Derive MIME types from file extensions"
    task update_from_file_extensions: :environment do
      (Journal.where("file_file_name IS NOT NULL") + StoredFile.where("file_file_name IS NOT NULL")).each do |file|

        print "#{file.class} #{file.id}: #{file.file_file_name} "

        extension = File.extname(file.file_file_name).sub(/^\./, "")
        if extension.blank?
          puts "WARNING: the file extension is blank!"
          next
        end

        mime_type = Mime::Type.lookup_by_extension(extension)
        if mime_type.blank?
          puts "WARNING: cannot look up extension #{extension}"
          next
        end

        if file.file_content_type == mime_type.to_s
          puts "is already set correctly to #{mime_type}"
          next
        end

        if file.update_attribute(:file_content_type, mime_type.to_s)
          puts "content type set to #{mime_type}"
        else
          puts "WARNING: COULD NOT set content type to #{mime_type}"
        end
      end
    end
  end
end

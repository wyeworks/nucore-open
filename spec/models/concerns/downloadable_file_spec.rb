# frozen_string_literal: true

require "rails_helper"

RSpec.describe DownloadableFile do

  # NOTE: just setting feature_setting: { active_storage: true }
  # on its own does not work as expected because DownloadableFile
  # has class methods that get evaluated on load.
  # Use the test classes below to ensure tests are run against
  # the expected modules.
  class ActiveStorageStoredFile < StoredFile
    include ActiveStorageFile
  end

  class PaperclipFileStoredFile < StoredFile
    include PaperclipFile
  end

  let(:facility) { create(:setup_facility) }
  let(:item) { create(:item, facility: facility) }
  let(:user) { create(:user) }
  let(:file_path) { "#{Rails.root}/spec/files/template1.txt" }
  let(:uploaded_file) { File.open(file_path) }
  let(:stored_file) do
    ActiveStorageStoredFile.new(
      product: item,
      name: "File 1",
      file: uploaded_file,
      file_type: "info",
      creator: user,
    )
  end

  context "active record", feature_setting: { active_storage: true } do

    it "is not persisted" do
      expect(stored_file).not_to be_persisted
    end

    it "can rename the file" do
      expect(stored_file.file.filename).not_to eq "error_report.csv"
      stored_file.update_filename("error_report.csv")
      expect(stored_file.file.filename).to eq "error_report.csv"
    end

    context "with a File" do
      it "can read the file content" do
        expect(stored_file.read_attached_file).to eq(File.read(file_path))
      end
    end

    context "with a StringIO" do
      let(:uploaded_file) { StringIO.new("c,s,v") }

      it "can read the file content" do
        expect(stored_file.read_attached_file).to eq("c,s,v")
      end
    end

    context "with test file upload" do
      let(:stored_file) do
        ActiveStorageStoredFile.new(
          product: item,
          file: Rack::Test::UploadedFile.new(file_path),
          creator: user,
        )
      end

      it "can read the file content" do
        expect(stored_file.read_attached_file).to eq(File.read(file_path))
      end
    end

    context "with no file attached" do
      let(:stored_file) do
        ActiveStorageStoredFile.new(
          product: item,
          name: "File 1",
          file_type: "info",
          creator: user,
        )
      end

      it "returns nil" do
        expect(stored_file.read_attached_file).to eq(nil)
      end
    end
  end

  context "paperclip", feature_setting: { active_storage: false } do

    it "is not persisted" do
      expect(stored_file).not_to be_persisted
    end

    it "can rename the file" do
      expect(stored_file.file.filename).not_to eq "error_report.csv"
      stored_file.update_filename("error_report.csv")
      expect(stored_file.file.filename).to eq "error_report.csv"
    end

    context "with a File" do
      it "can read the file content" do
        expect(stored_file.read_attached_file).to eq(File.read(file_path))
      end
    end

    context "with a StringIO" do
      let(:uploaded_file) { StringIO.new("c,s,v") }

      it "can read the file content" do
        expect(stored_file.read_attached_file).to eq("c,s,v")
      end
    end

    context "with test file upload" do
      let(:stored_file) do
        PaperclipFileStoredFile.new(
          product: item,
          file: Rack::Test::UploadedFile.new(file_path),
          creator: user,
        )
      end

      it "can read the file content" do
        expect(stored_file.read_attached_file).to eq(File.read(file_path))
      end
    end

    context "with no file attached" do
      let(:stored_file) do
        PaperclipFileStoredFile.new(
          product: item,
          name: "File 1",
          file_type: "info",
          creator: user,
        )
      end

      it "returns nil" do
        expect(stored_file.read_attached_file).to eq(nil)
      end
    end
  end

  context "with a persisted record" do
    let(:stored_file) do
      StoredFile.create(
        product: item,
        name: "File 1",
        file: uploaded_file,
        file_type: "info",
        creator: user,
      )
    end

    it "can attach and read the file content" do
      expect(stored_file).to be_persisted
      expect(stored_file.read_attached_file).to eq(File.read(file_path))
    end
  end

end



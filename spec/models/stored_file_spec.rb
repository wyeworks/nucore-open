# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoredFile do

  it "should require name" do
    is_expected.to validate_presence_of(:name)
  end

  it "should require file_type" do
    is_expected.to validate_presence_of(:file_type)
  end

  if SettingsHelper.feature_on?(:active_storage)
    context "active storage", feature_setting: { active_storage: true } do
      let(:stored_file) { StoredFile.create(file_type: "user_info") }

      it "should limit file size for user_info files" do
        expect(stored_file).to validate_size_of(:file).less_than(10.megabytes)
      end
    end
  else
    context "paperclip", feature_setting: { active_storage: false } do
      let(:stored_file) { StoredFile.create(file_type: "user_info") }

      it "should limit file size for user_info files" do
        expect(stored_file).to validate_attachment_size(:file).less_than(10.megabytes)
      end
    end
  end

  context "product_id" do
    it "should be required for 'info' file_type" do
      @fu = StoredFile.create(file_type: "info")
      expect(@fu).to validate_presence_of(:product_id)
    end

    it "should be required for 'template' file_type" do
      @fu = StoredFile.create(file_type: "template")
      expect(@fu).to validate_presence_of(:product_id)
    end
  end

  context "order_detail_id" do
    it "should be required for 'template_result' file_type" do
      @fu = StoredFile.create(file_type: "template_result")
      expect(@fu).to validate_presence_of(:order_detail_id)
    end
    it "should be required for 'sample_result' file_type" do
      @fu = StoredFile.create(file_type: "sample_result")
      expect(@fu).to validate_presence_of(:order_detail_id)
    end
  end

  context "when uploading" do
    let(:facility) { create(:setup_facility) }
    let(:item) { FactoryBot.create(:item, facility: facility) }

    let(:file1) { "#{Rails.root}/spec/files/template1.txt" }
    let(:file_upload) do
      item.stored_files.create(
        name: "File 1",
        file: File.open(file1),
        file_type: "info",
        creator: create(:user),
      )
    end

    it "is valid" do
      expect(file_upload).to be_valid
    end

    it "stored the file content" do
      expect(file_upload.read_attached_file).to eq(File.read(file1))
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoredFile do

  it "should require name" do
    is_expected.to validate_presence_of(:name)
  end

  it "should require file_type" do
    is_expected.to validate_presence_of(:file_type)
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
      expect(file_upload.read).to eq(File.read(file1))
    end
  end
end

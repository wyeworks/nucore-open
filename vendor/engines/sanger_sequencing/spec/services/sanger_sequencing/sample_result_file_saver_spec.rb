# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::SampleResultFileSaver do
  let(:user) { FactoryBot.create(:user) }
  let(:facility) { FactoryBot.create(:facility) }
  let(:product) { FactoryBot.build(:service, facility: facility).tap { |s| s.save(validate: false) } }
  let(:order) { FactoryBot.build(:order, user: user, created_by: user.id).tap { |o| o.save(validate: false) } }
  let(:order_detail) { FactoryBot.build(:order_detail, order: order, product: product).tap { |od| od.save(validate: false) } }
  let(:submission) { FactoryBot.create(:sanger_sequencing_submission, order_detail: order_detail, sample_count: 2) }
  let(:batch) { FactoryBot.create(:sanger_sequencing_batch, submissions: [submission]) }

  let(:saver) { described_class.new(batch, user, params) }

  let(:params) { { qqfile: fixture_file_upload(filename) } }

  describe "with a filename that doesn't begin with an integer" do
    let(:filename) { File.join(SangerSequencing::Engine.root, "spec/support/file_fixtures/invalid_file_name.txt") }

    it "does not save" do
      expect(saver.save).to be(false)
      expect(saver.errors).to be_added(:filename, :invalid)
    end
  end

  describe "with a filename that does not match a valid sample id" do
    let(:filename) { File.join(Rails.root, "tmp", "0_file.txt") }

    before do
      original_file = File.join(SangerSequencing::Engine.root, "spec/support/file_fixtures/SAMPLE_ID_file_name.txt")
      FileUtils.cp_r(original_file, filename)
    end

    it "does not save" do
      expect(saver.save).to be(false)
      expect(saver.errors).to be_added(:sample, :blank, id: "0")
    end
  end

  describe "with a filename that already exists" do
    let(:sample_id) { submission.samples.first.id }
    let(:filename) { File.join(Rails.root, "tmp", "#{sample_id}_file.txt") }
    let!(:existing_file) { FactoryBot.create(:stored_file, :results, order_detail: order_detail, name: "#{sample_id}_file.txt") }

    before do
      original_file = File.join(SangerSequencing::Engine.root, "spec/support/file_fixtures/SAMPLE_ID_file_name.txt")
      FileUtils.cp_r(original_file, filename)
    end

    it "does not save" do
      expect(saver.save).to be(false)
      expect(saver.errors[:name]).to include("Filename already exists for this order")
    end
  end

  describe "saving" do
    let(:sample_id) { submission.samples.first.id }
    let(:filename) { File.join(Rails.root, "tmp", "#{sample_id}_file.txt") }
    let(:stored_file) { StoredFile.last }
    before do
      original_file = File.join(SangerSequencing::Engine.root, "spec/support/file_fixtures/SAMPLE_ID_file_name.txt")
      FileUtils.cp_r(original_file, filename)
    end

    it "saves", :aggregate_failures do
      expect { saver.save }.to change(StoredFile, :count).by(1)
      expect(stored_file.order_detail).to eq(order_detail)
      expect(stored_file.file_type).to eq("sample_result")
      expect(stored_file.created_by).to eq(user.id)
      expect(stored_file.name).to eq("#{sample_id}_file.txt")
    end
  end
end

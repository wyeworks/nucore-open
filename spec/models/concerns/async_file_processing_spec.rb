# frozen_string_literal: true

require "rails_helper"

RSpec.describe AsyncFileProcessing do
  include ActiveJob::TestHelper

  class TestClass

    include ActiveModel::Model
    include ActiveRecord::AttributeAssignment
    include GlobalID::Identification
    include AsyncFileProcessing

    attr_accessor :status, :processed_at, :error_message, :file, :id

    def self.find(id)
      @repo[id.to_i]
    end

    def self.repo
      @repo ||= []
    end

    def initialize
      @status = "processing"
      @id = rand(10_000_000)
      self.class.repo[@id] = self
    end

    def update!(params)
      assign_attributes(params)
    end

    def save
      true
    end

    def process_file!
    end

  end

  describe "#enqueue" do
    subject(:instance) { TestClass.new }

    describe "before job runs" do
      it "enqueues the job " do
        expect { instance.enqueue }.to enqueue_a(FileProcessingJob)
      end

      it "sets the status to processing" do
        instance.enqueue
        expect(instance).to be_processing
      end
    end

    describe "on success" do
      it "sets the status to success" do
        perform_enqueued_jobs { instance.enqueue }
        expect(instance).to be_successful
      end
    end

    describe "failure" do
      it "sets the status to failed" do
        expect(instance).to receive(:process_file!).and_raise("Testing failure")
        perform_enqueued_jobs { instance.enqueue }
        expect(instance).to be_failed
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrnRenderer do
  let(:thursday) { Date.parse("2013-02-14") }
  let(:saturday) { Date.parse("2013-02-16") }

  describe "rendering with respect to today's date", :time_travel do
    let(:renderer) { described_class.new("/tmp") }

    describe "on weekends" do
      let(:now) { saturday }

      it "does not render" do
        expect(renderer).not_to receive(:render!)
        renderer.render
      end
    end

    describe "on a holiday" do
      let(:now) { thursday }

      before { Holiday.create! date: thursday }

      it "does render" do
        expect(renderer).to receive(:render!)
        renderer.render
      end
    end

    describe "on a regular weekday" do
      let(:now) { thursday }
      let!(:user) { create(:user) }
      let(:order_detail) { journal.journal_rows.first.order_detail }
      let!(:journal) do
        create(
          :journal,
          :with_completed_order,
          is_successful: nil,
          created_by: user.id,
        )
      end

      it "renders" do
        from_dir = "/tmp"
        today = thursday.to_s
        prn_name = "#{today.delete('-')}_A100.UMGL7056.IAL.INPUT"
        prn_src = File.join(from_dir, prn_name)

        expect(renderer).to receive(:render).and_call_original
        renderer.render
        rows = IO.read(prn_src).split("\n")
        # 1 header + 2 rows for 1 OrderDetail
        expect(rows.count).to eq 3
        # header row
        expect(rows.first).to include("$$$ALS00102142013", journal.facility.name, "UMAMH")
        # debit row
        expect(rows.second).to include(journal.facility.abbreviation, "00000000100DALS001", "UMAMH", order_detail.user.last_name, order_detail.to_s)
        # credit row
        expect(rows.third).to include(journal.facility.abbreviation, "00000000100CALS001", "UMAMH", order_detail.user.last_name, order_detail.to_s)
      end
    end
  end

  describe "rendering", :time_travel do
    let(:now) { thursday }

    let(:journal) { double("Journal", journal_rows: double("ActiveRecord::Relation")) }
    let(:relation) { double("ActiveRecord::Relation", all: [journal]) }
    let(:journal_prn) { double("UmassCorum::Journals::JournalPrn", journal: journal) }

    before :each do
      allow(Journal).to receive(:where).and_return relation
      allow_any_instance_of(PrnRenderer).to receive(:add_journal_to_file).and_return("")
      allow(FileUtils).to receive(:mv)
      allow(File).to receive(:open).and_yield []
    end

    describe "argument effects" do
      it "does not move a file when to_dir param is nil" do
        expect(FileUtils).not_to receive :mv
        PrnRenderer.render "/tmp"
      end

      it "moves a file when to_dir param is present" do
        expect(FileUtils).to receive :mv
        PrnRenderer.render "/tmp", "/tmp"
      end
    end

    describe "query window" do
      it "makes Friday the start day when running on Monday" do
        friday = saturday - 1.day
        monday = saturday + 2.days
        it_should_create_the_window friday, monday
      end

      it "makes 1 day ago the start day when running on non-Monday weekdays" do
        friday = thursday + 1.day
        it_should_create_the_window thursday, friday
      end

      def it_should_create_the_window(window_start, window_end)
        allow(Date).to receive(:today).and_return window_end
        start_date = Time.zone.parse("#{window_start} 17:00:00")
        end_date = Time.zone.parse("#{window_end} 17:00:00")
        expect(Journal).to receive(:where).with "created_at >= ? AND created_at < ? AND is_successful IS NULL", start_date, end_date
        PrnRenderer.render "/tmp"
      end
    end

    it "raises an error if no from_dir is specified" do
      expect { PrnRenderer.render }.to raise_error(ArgumentError)
    end

    it "opens the correct file" do
      from_dir = "/tmp"
      today = Date.today.to_s
      batch_file_name = "#{today.delete('-')}_A100.UMGL7056.IAL.INPUT"
      batch_file_src = File.join(from_dir, batch_file_name)
      expect(File).to receive(:open).with(batch_file_src, "w")
      PrnRenderer.render "/tmp"
    end

  end
end

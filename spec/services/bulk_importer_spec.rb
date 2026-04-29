# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkImporter do
  let(:user) { create(:user) }
  let(:csv_content) do
    <<~CSV
      Test Key,Another Key
      val1,val2
      val3,val4
    CSV
  end
  let(:bulk_import) do
    BulkImport.create!(
      import_type: "TestImport",
      created_by: user,
    )
  end

  before do
    allow(BulkImport).to receive(:import_classes) do
      { "TestImport" => test_importer_class }
    end

    bulk_import.file = StringIO.new(csv_content)
  end

  describe "#load!" do
    subject { bulk_import.loader }

    let(:test_importer_class) do
      Class.new(described_class) do
        def load_row(data)
          data[:test_key]
        end
      end
    end

    it "sets status to done" do
      expect { subject.load! }.to(
        change(bulk_import, :status).from('new').to('done')
      )
    end

    it "saves results" do
      subject.load!

      expect(bulk_import.reload.results).to eq(%w[val1 val3])
    end

    context "when some row fails" do
      let(:test_importer_class) do
        Class.new(described_class) do
          def load_row(data)
            raise NUCore::BulkImporterError, "Error loading #{data[:test_key]}"
          end
        end
      end

      it "sets status to done_errors" do
        expect { subject.load! }.to(
          change(bulk_import, :status).from("new").to("done_errors")
        )
      end

      it "saves error messages" do
        subject.load!

        expect(bulk_import.load_errors).to(
          eq([
               "#1: Error loading val1",
               "#2: Error loading val3",
             ])
        )
      end
    end

    context "on unexpected error" do
      let(:test_importer_class) do
        Class.new(described_class) do
          def load_row(_data)
            raise "Something broke"
          end
        end
      end

      it "sets the status as failure and raises the exception" do
        expect { subject.load! }.to raise_error(RuntimeError, "Something broke")

        expect(bulk_import.reload.status).to eq("failed")
        expect(bulk_import.failure).to eq("Something broke")
      end
    end

    describe "when header validation" do
      context "when fails" do
        let(:test_importer_class) do
          Class.new(described_class) do
            def load_row(data)
              data[:test_key]
            end

            def required_headers
              ["This Value", "That value"]
            end
          end
        end

        it "sets the status as failed" do
          expect { subject.load! }.to raise_error(RuntimeError)

          expect(bulk_import.reload.status).to eq("failed")
          expect(bulk_import.failure).to match(/required columns/i)
        end
      end

      context "when succeeds" do
        let(:test_importer_class) do
          Class.new(described_class) do
            def load_row(data)
              data[:test_key]
            end

            def required_headers
              ["Test Key", "Another Key"]
            end
          end
        end

        it "does not fail" do
          expect { subject.load! }.not_to raise_error

          expect(bulk_import.reload.status).to eq("done")
        end
      end
    end

    context "when run_in_transaction is true" do
      context "when nothing fails" do
        let(:test_importer_class) do
          Class.new(described_class) do
            def load_row(data)
              data[:test_key]
            end

            def run_in_transaction?
              true
            end
          end
        end

        it "runs successfully" do
          expect(BulkImport).to receive(:transaction)

          expect { subject.load! }.to(
            change(bulk_import, :status).from("new").to("done")
          )
        end
      end

      context "when some load_row fails" do
        let(:test_importer_class) do
          Class.new(described_class) do
            def load_row(data)
              raise NUCore::BulkImporterError, "Error loading #{data[:test_key]}"
            end

            def run_in_transaction?
              true
            end
          end
        end

        it "sets errors to failed" do
          expect { subject.load! }.to(
            change(bulk_import, :status).from("new").to("failed")
          )
        end

        it "stores error message" do
          subject.load!

          expect(bulk_import.reload.failure).to match(/error loading/i)
        end
      end
    end
  end
end

# frozen_string_literal: true

module SangerSequencing

  class WellPlatePresenter

    include TextHelpers::Translation

    attr_reader :well_plate, :plate_mode
    delegate :samples, to: :well_plate

    def initialize(well_plate, plate_mode)
      @well_plate = well_plate
      @plate_mode = plate_mode.presence || :default
    end

    def to_csv
      owner = alternative_csv_format? ? "" : text("owner")
      operator = alternative_csv_format? ? "" : text("operator")

      CSV.generate do |csv|
        csv << ["Container Name", "Plate ID", "Description", "ContainerType", "AppType", "Owner", "Operator", "PlateSealing", "SchedulingPref"]
        csv << ["",               "",         "",            "96-Well",       "Regular", owner, operator, "Septa", "1234"]
        csv << %w(AppServer AppInstance)
        csv << [plate_text("app_server"), plate_text("app_instance")]
        csv << ["Well", "Sample Name", "Comment"] + additional_columns.keys

        sample_rows.each do |row|
          csv << row
        end
      end
    end

    def sample_rows
      cleaned_cells.map do |position, sample|
        [position] + sample_row(sample, position)
      end
    end

    def translation_scope
      "sanger_sequencing.well_plate_files"
    end

    private

    def plate_text(key)
      default = "default.#{key}".to_sym
      text("#{plate_mode}.#{key}", default: default)
    end

    def cleaned_cells
      # Remove blank cells
      sorted_cells.reject { |_position, sample| sample.blank? }
    end

    def sorted_cells
      well_plate.cells.sort_by do |position, _sample|
        # Order by A01, B01, C01, etc.
        position =~ /\A([A-H])(\d{2})\z/
        [Regexp.last_match(2), Regexp.last_match(1)]
      end
    end

    def sample_row(sample, position)
      if position == "A1" && sample.reserved?
        ["PGEM_F", "CQLS"] + additional_columns.values
      else
        comment =  alternative_csv_format? ? sample.submission.order_detail.user : sample.customer_sample_id.to_s
        [sample.id.to_s, comment] + additional_columns.values
      end
    end

    # Define your additional columns as a set of hashes under `columns`:
    # Example:
    # custom_type:
    #   columns:
    #     Results Group 1: 50cm_POP7_BDv3
    #     Instrument Protocol 1: XLR_50POP7
    #     Analysis Protocol 1: XLR__50POP7_KBSeqAna
    def additional_columns
      columns = alternative_csv_format? ? "alternative_csv_columns" : "columns"
      I18n.t("#{translation_scope}.#{plate_mode}.#{columns}")
    end

    def alternative_csv_format?
      SettingsHelper.feature_on?(:alternative_csv_format)
    end

  end

end

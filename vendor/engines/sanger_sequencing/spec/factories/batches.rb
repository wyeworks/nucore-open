FactoryGirl.define do
  factory :sanger_sequencing_batch, class: SangerSequencing::Batch do
    well_plates_raw []
  end
end

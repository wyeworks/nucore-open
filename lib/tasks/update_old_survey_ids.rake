# frozen_string_literal: true

task zero_pad_survey_ids: :environment do
  ExternalServiceReceiver.where.not(external_id: nil).each do |receiver|
    print "#{receiver.class} #{receiver.id} external_id: "
    match = receiver.external_id.match(/\A([A-Z][A-Z]-)(\d{1,3})\z/)
    if match
      receiver.external_id = "#{match[1]}#{format '%04d', match[2]}"
      receiver.save!
      puts "updated to #{receiver.external_id}"
    else
      puts "skipping #{receiver.external_id}"
    end
  end
end

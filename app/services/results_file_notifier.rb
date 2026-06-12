# frozen_string_literal: true

class ResultsFileNotifier

  attr_reader :file

  def initialize(file)
    @file = file
  end

  def notify
    return unless SettingsHelper.feature_on?("orders.results_file_notifications")

    EmailEvent.notify(file.user, debounce_key) do
      ResultsFileNotifierMailer.file_uploaded(file).deliver_later
    end
  end

  private

  def debounce_key
    # De-bounce emails based on the order detail so we don't overwhelm the user.
    # This could easily be changed to just the user or just the facility by
    # changing this key
    [:results_file, :file_uploaded, :order_detail, file.order_detail]
  end

end

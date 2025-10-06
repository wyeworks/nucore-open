# frozen_string_literal: true

module JournalsHelper
  def journal_status_options(_journal)
    [[' ', nil], ['Succeeded, no errors', 'succeeded'], ['Succeeded, with errors', 'succeeded_errors'], ['Failed', 'failed']]
  end
end

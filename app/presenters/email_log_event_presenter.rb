# frozen_string_literal: true

class EmailLogEventPresenter < SimpleDelegator
  def email_to
    email_to = metadata["to"] || []

    if email_to.is_a?(Array)
      email_to.join(", ")
    else
      email_to
    end
  end

  def email_subject
    metadata["subject"]
  end
end

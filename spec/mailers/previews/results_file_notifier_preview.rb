# frozen_string_literal: true

class ResultsFileNotifierPreview < ActionMailer::Preview

  def file_uploaded
    file = FactoryBot.build(
      :stored_file,
      :results,
      creator: User.first,
      order_detail: OrderDetail.first
    )

    ResultsFileNotifierMailer.file_uploaded(file)
  end

end

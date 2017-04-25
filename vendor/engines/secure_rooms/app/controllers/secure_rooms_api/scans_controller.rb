module SecureRoomsApi

  class ScansController < SecureRoomsApi::ApiController

    before_action :load_user_and_reader

    def scan
      verdict = SecureRooms::CheckAccess.new.authorize(
        @user,
        @card_reader,
        requested_account_id: params[:account_identifier],
      )

      SecureRooms::AccessManager.process(verdict)

      render SecureRooms::ScanResponsePresenter.present(verdict)
    end

    private

    def load_user_and_reader
      @user = User.find_by!(card_number: params[:card_number])
      @card_reader = SecureRooms::CardReader.find_by!(
        card_reader_number: params[:reader_identifier],
        control_device_number: params[:controller_identifier],
      )
    end

  end

end

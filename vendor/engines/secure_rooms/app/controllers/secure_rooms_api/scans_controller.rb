# frozen_string_literal: true

module SecureRoomsApi

  class ScansController < SecureRoomsApi::ApiController

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    before_action :load_user_and_reader

    def scan
      verdict = SecureRooms::CheckAccess.new.authorize(
        @user,
        @card_reader,
        requested_account_id: params[:account_identifier],
        card_number: params[:card_number],
      )

      SecureRooms::AccessManager.process(verdict)

      render SecureRooms::ScanResponsePresenter.present(verdict)
    end

    private

    def load_user_and_reader
      @user = User.for_card_number(params[:card_number])

      @card_reader = SecureRooms::CardReader.find_by!(
        card_reader_number: params[:reader_identifier],
        control_device_number: params[:controller_identifier].upcase,
      )
    end

    def render_not_found(exception)
      render json: { error: exception.message }, status: 404
    end

  end

end

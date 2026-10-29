# frozen_string_literal: true

module SecureRoomsApi
  class EventsController < SecureRoomsApi::ApiController
    def create
      SecureRooms::AlarmEvent.create!(
        alarm_event_params.merge(
          message_time: parse_time(params[:message_time]),
          raw_post: request.raw_post,
        ),
      )

      head :ok
    end

    private

    def alarm_event_params
      params.permit(
        :additional_data,
        :class_code,
        :event_code,
        :event_description,
        :mac_address,
        :message_id,
        :message_time,
        :message_type,
        :priority,
        :task_code,
        :task_description,
      )
    end

    def parse_time(time_str)
      format_str = "%H:%M:%S %Z %m/%d/%Y"
      DateTime.strptime(time_str, format_str)
    end
  end
end

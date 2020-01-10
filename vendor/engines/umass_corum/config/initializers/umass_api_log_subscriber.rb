# frozen_string_literal: true

module UmassCorum

  class LogSubscriber < ActiveSupport::LogSubscriber

    def get_speed_type(event)
      render(event, "Speed type GET from API: #{event.payload[:speed_type]}")
    end

    def get_owl_certifications(event)
      render(event, "Queryied OWL API: #{event.payload[:emplid]}")
    end

    private

    def render(event, string, display_color: GREEN)
      return unless logger.debug?

      prefix = color("[UmassCorum] (#{event.duration.round(1)}ms)", display_color, true)
      debug "#{prefix} #{string}"
    end

  end

end

UmassCorum::LogSubscriber.attach_to :umass_corum

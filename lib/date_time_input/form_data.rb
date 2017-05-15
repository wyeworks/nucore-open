module DateTimeInput

  class FormData

    def initialize(time)
      @time = time
    end

    def self.from_param(param)
      from_param!(param)
    rescue ArgumentError
      new(nil)
    end

    def self.from_param!(param)
      return new(param) if param.is_a?(Time)
      param = param.with_indifferent_access

      str = param[:date]
      format = "%m/%d/%Y"

      if check_time_param!(param)
        str += " #{param[:hour]}:#{param[:minute].to_s.rjust(2, '0')} #{param[:ampm]}"
        format += " %H:%M %p"
      end

      new(Time.strptime(str, format))
    end

    def self.check_time_param!(param)
      if %w(hour minute ampm).all? { |k| param.key? k }
        true
      elsif %w(hour minute ampm).none? { |k| param.key? k }
        false
      else
        raise ArgumentError, "Must have all or none of [:hour, :minute, :ampm] keys"
      end
    end

    def date
      return unless @time
      I18n.l(@time.to_date, format: :usa)
    end

    def hour
      return unless @time
      @time.strftime("%I").to_i
    end

    def minute
      return unless @time
      @time.min
    end

    def ampm
      return unless @time
      @time.strftime("%p")
    end

    def to_time
      @time
    end

    def to_h
      {
        date: date,
        hour: hour,
        minute: minute,
        ampm: ampm,
      }
    end

  end

end

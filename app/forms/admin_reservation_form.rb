class AdminReservationForm

  include ActiveModel::Validations
  include DateHelper

  REPEAT_OPTIONS = %w(
    daily
    weekdays_only
    weekly
    monthly
  ).freeze

  delegate :to_key, :to_model, to: :reservation
  delegate :category, :reserve_start_date, :reserve_start_hour,
           :reserve_start_min, :reserve_start_meridian, :duration_mins,
           :reserve_end_date, :reserve_end_hour, :reserve_end_min,
           :reserve_end_meridian, :admin_note, :expires?,
           :expires_mins_before, to: :reservation
  delegate :assign_times_from_params, to: :reservation

  attr_accessor :repeats, :repeat_frequency, :repeat_end_date
  attr_reader :reservation

  validates :repeat_frequency, inclusion: { in: REPEAT_OPTIONS, allow_nil: true }
  validates :repeat_end_date, presence: true, if: :repeats?

  validate :cannot_exceed_max_end_date
  validate :repeat_end_date_after_initial_date

  def initialize(reservation)
    @reservation = reservation
  end

  def assign_attributes(attrs)
    @reservation.assign_attributes(attrs.except(:repeat_frequency, :repeat_end_date, :repeats))
    @repeats = attrs[:repeats]
    @repeat_frequency = attrs[:repeat_frequency]
    @repeat_end_date = parse_usa_date(attrs[:repeat_end_date])
  end

  def valid?
    [@reservation.valid?, super].each {}
    # errors does not support `merge`
    @reservation.errors.each do |k, errors|
      errors.add(k, errors)
    end
    errors.none?
  end

  def save
    if valid?
      # @reservation.save
      reservations = create_recurring_reservations
      reservations.map(&:save).all?
    else
      false
    end
  end

  def create_recurring_reservations
    recurrence = Recurrence.new(reservation.reserve_start_at, reservation.reserve_end_at, until_time: repeat_end_date.try(:end_of_day))
    group_id = SecureRandom.uuid

    repeats = case repeat_frequency
              when "daily"
                recurrence.daily
              when "weekdays_only"
                recurrence.weekdays
              when "weekly"
                recurrence.weekly
              when "monthly"
                recurrence.monthly
              else
                # no repeat
                recurrence.daily.take(1)
              end

    repeats.map do |t|
      @reservation.dup.tap do |res|
        res.assign_attributes(reserve_start_at: t.start_time, reserve_end_at: t.end_time, group_id: group_id)
      end
    end
  end

  def max_end_date
    12.weeks.from_now
  end

  def cannot_exceed_max_end_date
    if repeat_end_date && repeat_end_date > max_end_date
      errors.add :repeat_end_date, :too_far_in_future
    end
  end

  def repeat_end_date_after_initial_date
    if repeat_end_date && repeat_end_date < parse_usa_date(reserve_start_date)
      errors.add :repeat_end_date, :must_be_after_initial_reservation
    end
  end

  def repeats?
    repeats == "1"
  end

end

#####
# specs for form object (validation rules, other recurrence types)
# add group id (uuid)

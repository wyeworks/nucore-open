# frozen_string_literal: true

class RecurringTaskConfig

  extend Enumerable

  # A convenience method to allow calling #each
  # and other enumerable methods (#to_a) to get
  # the list of task params.
  def self.each(&block)
    recurring_tasks.each do |task_params|
      block.call(RecurringTask.new(*task_params))
    end
  end

  # Returns an array of recurring task classes, their calling methods,
  # and how often (in minutes) to run the task.
  # Engines can append to this list.
  def self.recurring_tasks
    @@recurring_tasks ||= [
      [AutoExpireReservation, :perform, 5],
      [EndReservationOnly, :perform, 5],
      [AutoLogout, :perform, 5],
      [InstrumentOfflineReservationCanceler, :cancel!, 1],
      [AdminReservationExpirer, :expire!, 1],
      [AutoCanceler, :cancel_reservations, 1],
    ]
  end

  # PORO for wrapping various recurring task classes
  # in a consistent manner.
  RecurringTask = Struct.new(:task_class, :call_method, :frequency) do
    def invoke!(start_time)
      task_class.new.public_send(call_method) if invoke?(start_time)
    end

    def invoke?(start_time)
      start_time.min % frequency == 0
    end
  end

end

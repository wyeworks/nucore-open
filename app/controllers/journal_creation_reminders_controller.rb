# frozen_string_literal: true

class JournalCreationRemindersController < ApplicationController

  load_and_authorize_resource

  layout "two_column"
  before_action { @active_tab = "global_settings" }

  def index
    @journal_creation_reminders = JournalCreationReminder.order(ends_at: :desc)
  end

  def new
    default_start_date = [JournalCreationReminder.maximum(:starts_at), Time.current].compact.max
    @journal_creation_reminder.starts_at = l(default_start_date.to_date, format: :usa)
  end

  def create
    if @journal_creation_reminder.save
      redirect_to journal_creation_reminders_path, notice: t("journal_creation_reminders.create.success")
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @journal_creation_reminder.update(journal_creation_reminder_params)
      redirect_to journal_creation_reminders_path, notice: t("journal_creation_reminders.update.success")
    else
      render :edit
    end
  end

  def destroy
    @journal_creation_reminder.destroy
    redirect_to journal_creation_reminders_path, notice: t("journal_creation_reminders.destroy.success")
  end

  private

  def journal_creation_reminder_params
    params.expect(journal_creation_reminder: [:message, :starts_at, :ends_at])
  end

end

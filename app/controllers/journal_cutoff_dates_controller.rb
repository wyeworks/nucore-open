# frozen_string_literal: true

class JournalCutoffDatesController < ApplicationController

  load_and_authorize_resource

  layout "two_column"
  before_action { @active_tab = "global_settings" }

  def index
    @journal_cutoff_dates = JournalCutoffDate.recent_and_upcoming
    @first_valid_date = JournalCutoffDate.first_valid_date
  end

  def new
    @journal_cutoff_date.cutoff_date = default_next_cutoff
  end

  def create
    if @journal_cutoff_date.save
      redirect_to journal_cutoff_dates_path, notice: t("journal_cutoff_dates.create.success")
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @journal_cutoff_date.update(journal_cutoff_date_params)
      redirect_to journal_cutoff_dates_path, notice: t("journal_cutoff_dates.update.success")
    else
      render :edit
    end
  end

  def destroy
    @journal_cutoff_date.destroy
    redirect_to journal_cutoff_dates_path, notice: t("journal_cutoff_dates.destroy.success")
  end

  private

  def default_next_cutoff
    max_future_time = [JournalCutoffDate.maximum(:cutoff_date), Time.current].compact.max

    hour, min = Settings.financial.default_journal_cutoff_time.split(":")
    # in_time_zone is necessary to get beginning_of_month to respect timezones
    max_future_time.in_time_zone.next_month.beginning_of_month.change(hour: hour, min: min)
  end

  def journal_cutoff_date_params
    params.expect(journal_cutoff_date: [cutoff_date: [:date, :hour, :minute, :ampm]])
  end

end

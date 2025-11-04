# frozen_string_literal: true

class HolidaysController < ApplicationController

  load_and_authorize_resource

  layout "two_column"
  before_action { @active_tab = "global_settings" }

  def index
    @holidays = Holiday.future.order(:date)
  end

  def new
  end

  def create
    @holiday.date = parse_usa_date(holiday_params[:date])

    if @holiday.save
      redirect_to holidays_path, notice: t("holidays.create.success")
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @holiday.update(date: parse_usa_date(holiday_params[:date]))
      redirect_to holidays_path, notice: t("holidays.update.success")
    else
      render :edit
    end
  end

  def destroy
    @holiday.destroy
    redirect_to holidays_path, notice: t("holidays.destroy.success")
  end

  private

  def holiday_params
    params.expect(holiday: [:date])
  end

end

# frozen_string_literal: true

class FacilityJournalsController < ApplicationController

  include DateHelper
  include CSVHelper
  include OrderDetailsCsvExport
  include SortableBillingTable

  admin_tab     :all
  before_action :check_acting_as
  before_action :check_billing_access
  before_action :init_journals, except: :create
  before_action :enable_sorting, only: [:new]

  layout lambda {
    action_name.in?(%w(new)) ? "two_column_head" : "two_column"
  }

  def initialize
    @subnav     = "billing_nav"
    @active_tab = "admin_billing"
    super
  end

  # GET /facilities/journals
  def index
    set_pending_journals if @journals.current_page == 1
  end

  # GET /facilities/journals/new
  def new
    raise ActiveRecord::RecordNotFound if current_facility.cross_facility?

    order_details = OrderDetail.for_facility(current_facility).need_journal
    @search_form = TransactionSearch::SearchForm.new(params[:search])
    @search =
      TransactionSearch::Searcher
      .new(facilities: current_facility.cross_facility?)
      .search(order_details, @search_form)

    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details.reorder(sort_clause)
    @journal_creation_reminder = JournalCreationReminder.current.first

    set_earliest_journal_date

    unless current_facility.has_pending_journals?
      @order_detail_action = :create
      @action_date_field = { journal_date: @earliest_journal_date }
    end

    @valid_order_details, @invalid_order_details = AccountValidator::ValidatorFactory.partition_valid_order_details(@order_details.unexpired_account)
    @invalid_order_details += @order_details.expired_account
    @invalid_order_details = @invalid_order_details.sort_by(&:fulfilled_at)

    respond_to do |format|
      format.csv do
        # used for "Export as CSV" link for order details with expired accounts
        @order_details = @invalid_order_details
        handle_csv_search
      end
      format.any {}
    end
  end

  # PUT /facilities/journals/:id
  def update
    @pending_journal = @journal

    action = Journals::Closer.new(@pending_journal, params.fetch(:journal, empty_params).merge(updated_by: session_user.id))

    if action.perform params[:journal_status]
      flash[:notice] = I18n.t "controllers.facility_journals.update.notice"
      LogEvent.log(@pending_journal, :closed, session_user)
      redirect_to facility_journals_path(current_facility)
    else
      @order_details = OrderDetail.for_facility(current_facility).need_journal
      set_earliest_journal_date
      set_pending_journals

      # move error messages for pending journal into the flash
      if @pending_journal.errors.any?
        flash.now[:error] = @journal.errors.full_messages.join("<br/>").html_safe
      end

      @earliest_journal_date = params[:journal_date] || @earliest_journal_date
      render action: :index
    end
  end

  # POST /facilities/journals
  def create
    raise ActiveRecord::RecordNotFound if current_facility.cross_facility?

    new_journal_from_params
    verify_journal_date_format

    # The referer can have a crazy long query string depending on how many checkboxes
    # are selected. We've seen Apache not like stuff like that and give a "malformed
    # header from script. Bad header" error which causes the page to completely bomb out.
    # (See Task #48311). This is just preventative.
    referer = response.headers["Referer"]
    response.headers["Referer"] = referer[0..referrer.index("?")] if referer.present?

    if @journal.errors.blank? && @journal.save
      @journal.create_spreadsheet if Journals::JournalFormat.exists?(:xls)
      flash[:notice] = I18n.t("controllers.facility_journals.create.notice")
      LogEvent.log(@journal, :create, current_user)
      redirect_to facility_journals_path(current_facility)
    else
      flash_error_messages
      redirect_to new_facility_journal_path
    end
  end

  # GET /facilities/journals/:id
  def show
    @journal_rows = @journal.journal_rows
    @log_event = LogEvent.where(loggable_type: "Journal", loggable_id: @journal.id, event_type: "closed").last
    respond_to do |format|
      format.html {}

      format.xml do
        @filename = "journal_#{@journal.id}_#{@journal.created_at.strftime('%Y%m%d')}"
        headers["Content-Disposition"] = "attachment; filename=\"#{@filename}.xml\""
      end

      format.xls { redirect_to @journal.download_url }

      # Fallback for other formats
      format.any do
        journal_format = Journals::JournalFormat.find(params[:format])
        send_data journal_format.render(@journal), journal_format.options if journal_format
      end
    end
  end

  def reconcile
    process_reconciliation(:reconcile, "reconciled")
  end

  def unreconcile
    unless SettingsHelper.feature_on?(:allow_mass_unreconciling)
      raise CanCan::AccessDenied, I18n.t("controllers.facility_journals.unreconcile.feature_disabled")
    end

    unless current_user.administrator?
      raise CanCan::AccessDenied, I18n.t("controllers.facility_journals.unreconcile.access_denied")
    end

    process_reconciliation(:unreconcile)
  end

  private

  def process_reconciliation(action, order_status = nil)
    reconciler = OrderDetails::Reconciler.new(
      @journal.order_details,
      params[:order_detail],
      @journal.journal_date,
      order_status
    )

    count = if action == :reconcile
              reconciler.reconcile_all
            else
              reconciler.unreconcile_all
            end

    if count > 0
      flash[:notice] = I18n.t("controllers.facility_journals.#{action}.success", count: count)
    elsif reconciler.full_errors.any?
      flash[:error] = reconciler.full_errors.join("<br />").html_safe
    else
      flash[:error] = I18n.t("controllers.facility_journals.#{action}.errors.none_eligible")
    end

    redirect_to [current_facility, @journal]
  end

  def new_journal_from_params
    @journal = Journal.new(
      created_by: session_user.id,
      journal_date: parse_usa_date(params[:journal_date]),
      order_details_for_creation:
    )
  end

  def verify_journal_date_format
    if params[:journal_date].present? && !usa_formatted_date?(params[:journal_date])
      @journal.errors.add(:journal_date, :blank)
    end
  end

  def order_details_for_creation
    return [] unless params[:order_detail_ids].present?
    OrderDetail.for_facility(current_facility).need_journal.includes(:account, :product, order: :user).where_ids_in(params[:order_detail_ids])
  end

  def set_pending_journals
    @pending_journals = @journals.where(is_successful: nil)
  end

  def set_earliest_journal_date
    @earliest_journal_date = [
      @order_details.collect(&:fulfilled_at).max,
      JournalCutoffDate.first_valid_date,
    ].compact.max
  end

  def init_journals
    @journals = Journal.for_facilities(manageable_facilities, manageable_facilities.size > 1).includes(:journal_rows).order("journals.created_at DESC")
    jid = params[:id] || params[:journal_id]
    @journal = @journals.find(jid) if jid
    @journals = @journals.paginate(page: params[:page], per_page: 10)
  end

  def flash_error_messages
    msg = ""

    @journal.errors.full_messages.each do |error|
      msg += "#{error}<br/>"

      if msg.size > 2000 # don't overflow session (flash) cookie
        msg += I18n.t "controllers.facility_journals.create.more_errors"
        break
      end
    end

    flash[:error] = msg.html_safe if msg.present?
  end

end

class ControllersController < ApplicationController
  before_action :set_controller, only: [ :show, :destroy, :sync, :backfill, :history, :calendar, :day, :claim_zone_label ]
  around_action :in_controller_timezone, only: [ :show, :history, :calendar, :day ]

  def index
    @controllers = Controller.order(:name)
  end

  def show
    @zones = @controller.zones.ordered
    @zones = @zones.enabled unless params[:show_disabled].present?
    @recent_runs = @controller.watering_runs.limit(20)
    @heatmap_days = @controller.daily_watering_minutes(1.year.ago.to_date..Date.current)
    visible_zone_ids = @zones.ids
    @minutes_by_zone = @controller.minutes_by_zone.select { |zone, _minutes| visible_zone_ids.include?(zone.id) }
    @unmatched_labels = @controller.events.zone_runs.where(zone_id: nil).map(&:zone_label).tally.sort_by { |_label, count| -count }
    @minutes_by_month = @controller.minutes_by_month
  end

  def history
    @zones = @controller.zones.ordered
    @zones = @zones.enabled unless params[:show_disabled].present? || params[:zone_id].present?
    @events = @controller.events.recent_first.includes(:zone)
    @events = @events.where(zone_id: params[:zone_id]) if params[:zone_id].present?
    if params[:label].present?
      pattern = "#{Event.sanitize_sql_like(params[:label])}%"
      @events = @events.where("summary LIKE ? OR summary LIKE ?", pattern, "Soaking #{pattern}")
    end
    @events = @events.zone_runs if params[:runs_only].present?
    @events = @events.limit(300)
  end

  def calendar
    @month = params[:month].present? ? Date.parse("#{params[:month]}-01") : Date.current.beginning_of_month
    @runs_by_day = @controller.watering_runs(@month.beginning_of_month.beginning_of_day..@month.end_of_month.end_of_day)
                              .group_by { |event| event.occurred_at.to_date }
  end

  def claim_zone_label
    zone = @controller.zones.find(params[:zone_id])
    linked = zone.claim_label!(params[:label])
    redirect_to @controller, notice: "Linked #{linked} events from “#{params[:label]}” to #{zone.name}."
  end

  def day
    @date = Date.parse(params[:date])
    range = @date.beginning_of_day..@date.end_of_day
    @runs = @controller.watering_runs(range).sort_by(&:run_started_at)
    @day_events = @controller.events.includes(:zone).between(range.begin, range.end).order(:occurred_at)
  end

  def new
    @controller_record = Controller.new
  end

  # Manually add a controller by its Rachio device id — lets you register
  # old controllers that are no longer attached to your account.
  def create
    @controller_record = Controller.new(rachio_id: params.expect(device: [ :rachio_id ])[:rachio_id].strip)
    @controller_record.sync_from_rachio!
    redirect_to @controller_record, notice: "Controller added."
  rescue Rachio::Error => e
    @controller_record.errors.add(:base, e.message)
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid
    redirect_to controllers_path, alert: "That controller is already added."
  end

  def destroy
    @controller.destroy!
    redirect_to controllers_path, notice: "Controller removed."
  end

  def sync
    SyncControllerJob.perform_later(@controller)
    redirect_to @controller, notice: "Sync queued."
  end

  def backfill
    @controller.start_backfill!
    redirect_to @controller, notice: "Full history backfill started."
  end

  def sync_account
    SyncAccountJob.perform_later
    redirect_to controllers_path, notice: "Account sync queued — controllers will appear shortly."
  end

  private

  def set_controller
    @controller_record = @controller = Controller.find(params[:id])
  end

  def in_controller_timezone(&block)
    Time.use_zone(@controller.timezone.presence || Time.zone, &block)
  end
end

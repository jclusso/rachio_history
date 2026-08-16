# Merging a replaced controller's history into the controller that took over
# for it. Every merge goes through a preview first: this moves thousands of
# events at once, and it is the one screen where a mis-click is expensive.
class MergesController < ApplicationController
  before_action :set_controller
  before_action :set_successor, only: [ :new, :create ]

  def new
    @pairing = @controller.merge_pairing(@successor)
    @overlapping_days = @controller.overlapping_run_days(@successor)
  end

  def create
    moved = @controller.events.count
    @controller.merge_into!(@successor)
    redirect_to @successor, notice: "Merged #{helpers.number_with_delimiter(moved)} events from #{@controller.name} into #{@successor.name}."
  end

  def destroy
    return redirect_to manage_controller_path(@controller), alert: "That controller hasn't been merged." unless @controller.merged?

    successor = @controller.merged_into
    restored = @controller.merged_events_count
    @controller.unmerge!
    redirect_to @controller, notice: "Moved #{helpers.number_with_delimiter(restored)} events back to #{@controller.name} from #{successor.name}."
  end

  private

  def set_controller
    @controller = Controller.find(params[:controller_id])
  end

  def set_successor
    @successor = Controller.find_by(id: params[:successor_id])
    error = @controller.merge_error(@successor)
    redirect_to manage_controller_path(@controller), alert: error if error
  end
end

class ZonesController < ApplicationController
  def show
    @zone = Zone.find(params[:id])
    Time.use_zone(@zone.controller.timezone.presence || Time.zone) { render :show }
  end
end

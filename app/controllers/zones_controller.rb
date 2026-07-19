class ZonesController < ApplicationController
  def show
    @zone = Zone.find(params[:id])
  end
end

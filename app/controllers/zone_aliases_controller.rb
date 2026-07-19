class ZoneAliasesController < ApplicationController
  def destroy
    zone_alias = ZoneAlias.find(params[:id])
    zone = zone_alias.zone
    zone_alias.release!
    redirect_to zone, notice: "Alias “#{zone_alias.name}” removed and its events unassigned."
  end
end

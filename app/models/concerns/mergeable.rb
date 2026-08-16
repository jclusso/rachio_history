# Folding a replaced controller's history into the controller that took over
# for it, so a new box doesn't split a yard's history in two.
#
# The merge repoints events at the successor and its matching zones rather
# than teaching every query to span both devices — one controller stays one
# place, and the heatmap, stats and calendar keep working untouched. Each
# event remembers where it came from, so a merge can be undone.
module Mergeable
  extend ActiveSupport::Concern

  included do
    belongs_to :merged_into, class_name: "Controller", optional: true
    has_many :predecessors, class_name: "Controller", foreign_key: :merged_into_id,
             inverse_of: :merged_into, dependent: :nullify

    scope :active, -> { where(merged_into_id: nil) }
    scope :merged, -> { where.not(merged_into_id: nil) }
  end

  def merged?
    merged_into_id.present?
  end

  # Controllers this one could be folded into: any other device still in service.
  def merge_candidates
    Controller.active.where.not(id: id).order(:name)
  end

  # How many events this controller handed to its successor.
  def merged_events_count
    Event.where(source_controller_id: id).count
  end

  # The successor zone an old zone's history should land on. Zone numbers are
  # the stable identity when a box is swapped in place; fall back to the name
  # for a rewired controller.
  def matching_zone(zone)
    zones.find_by(number: zone.number) || zones.find_by(name: zone.name)
  end

  # [ [old zone, successor zone or nil], ... ] — the plan a merge would follow,
  # rendered for confirmation before anything is written.
  def merge_pairing(successor)
    zones.ordered.map { |zone| [ zone, successor.matching_zone(zone) ] }
  end

  # Days both devices recorded completed runs. Normally empty — one controller
  # replaces another — but overlap means the merged totals double-count, so it
  # is worth showing before committing.
  def overlapping_run_days(successor)
    days = ->(controller) { controller.events.zone_completed.pluck(:occurred_at).map(&:to_date).uniq }
    (days.call(self) & days.call(successor)).sort
  end

  def merge_error(successor)
    return "Pick a controller to merge into." if successor.blank?
    return "A controller can't be merged into itself." if successor == self
    return "#{name} has already been merged into #{merged_into.name}." if merged?

    "#{successor.name} has itself been merged into #{successor.merged_into.name}." if successor.merged?
  end

  # Hand this controller's history to its successor. Events keep their original
  # controller and zone ids so #unmerge! can put everything back.
  def merge_into!(successor)
    raise ArgumentError, merge_error(successor) if merge_error(successor)

    transaction do
      merge_pairing(successor).each do |zone, successor_zone|
        # No counterpart: drop the link rather than leave events pointing at a
        # zone on another controller. They surface under "Unmatched zone names"
        # on the successor, where they can be assigned by hand.
        next zone.events.update_all(source_zone_id: zone.id, zone_id: nil) if successor_zone.nil?

        if successor_zone.name != zone.name
          successor_zone.zone_aliases.find_or_create_by!(name: zone.name)
        end
        zone.events.update_all(source_zone_id: zone.id, zone_id: successor_zone.id)
      end

      events.update_all([ "source_controller_id = controller_id, controller_id = ?", successor.id ])
      update!(merged_into: successor)
    end
  end

  # Put every event this controller handed over back where it was.
  def unmerge!
    return false unless merged?

    transaction do
      moved = Event.where(source_controller_id: id)
      moved.where.not(source_zone_id: nil).update_all("zone_id = source_zone_id")
      moved.update_all(controller_id: id, source_controller_id: nil, source_zone_id: nil)
      update!(merged_into: nil)
    end

    true
  end
end

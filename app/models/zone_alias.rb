# A former name a zone was known by. Events reference zones only by the
# name embedded in their summary, so aliases let renamed zones keep their
# full history.
class ZoneAlias < ApplicationRecord
  belongs_to :zone

  validates :name, presence: true, uniqueness: { scope: :zone_id }

  def linked_events_count
    zone.events.where("summary LIKE ? OR summary LIKE ?", "#{self.class.sanitize_sql_like(name)}%", "Soaking #{self.class.sanitize_sql_like(name)}%").count
  end

  # Undo the alias: unlink the events it claimed, then remove it.
  def release!
    pattern = "#{self.class.sanitize_sql_like(name)}%"
    zone.events.where("summary LIKE ? OR summary LIKE ?", pattern, "Soaking #{pattern}")
        .update_all(zone_id: nil)
    destroy!
  end
end

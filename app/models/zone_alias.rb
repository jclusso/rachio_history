# A former name a zone was known by. Events reference zones only by the
# name embedded in their summary, so aliases let renamed zones keep their
# full history.
class ZoneAlias < ApplicationRecord
  belongs_to :zone

  validates :name, presence: true, uniqueness: { scope: :zone_id }
end

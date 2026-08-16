class AddControllerMerging < ActiveRecord::Migration[8.1]
  def change
    add_reference :controllers, :merged_into, foreign_key: { to_table: :controllers }

    # Where an event lived before a merge repointed it. Deliberately plain
    # integers rather than references: they must survive as a record of the
    # original owner, not cascade with it.
    add_column :events, :source_controller_id, :integer
    add_column :events, :source_zone_id, :integer
    add_index :events, :source_controller_id
  end
end

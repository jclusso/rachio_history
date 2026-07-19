class CreateZoneAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :zone_aliases do |t|
      t.references :zone, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    add_index :zone_aliases, [ :zone_id, :name ], unique: true
  end
end

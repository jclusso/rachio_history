class CreateControllers < ActiveRecord::Migration[8.1]
  def change
    create_table :controllers do |t|
      t.string :rachio_id, null: false, index: { unique: true }
      t.string :name
      t.string :model
      t.string :serial_number
      t.string :mac_address
      t.string :status
      t.string :timezone
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.datetime :rachio_created_at
      t.datetime :last_synced_at
      t.datetime :backfill_started_at
      t.datetime :backfill_cursor_at
      t.datetime :backfill_completed_at

      t.timestamps
    end
  end
end

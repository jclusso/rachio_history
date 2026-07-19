class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :controller, null: false, foreign_key: true
      t.references :zone, foreign_key: true
      t.string :rachio_id, null: false, index: { unique: true }
      t.string :category
      t.string :event_type
      t.string :sub_type
      t.text :summary
      t.datetime :occurred_at, null: false
      t.json :raw

      t.timestamps
    end

    add_index :events, [ :controller_id, :occurred_at ]
    add_index :events, [ :zone_id, :occurred_at ]
    add_index :events, :event_type
  end
end

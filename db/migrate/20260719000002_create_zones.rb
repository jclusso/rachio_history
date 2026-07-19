class CreateZones < ActiveRecord::Migration[8.1]
  def change
    create_table :zones do |t|
      t.references :controller, null: false, foreign_key: true
      t.string :rachio_id, null: false, index: { unique: true }
      t.string :name
      t.integer :number
      t.boolean :enabled, default: true
      t.string :image_url

      t.timestamps
    end
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_19_000003) do
  create_table "controllers", force: :cascade do |t|
    t.datetime "backfill_completed_at"
    t.datetime "backfill_cursor_at"
    t.datetime "backfill_started_at"
    t.datetime "created_at", null: false
    t.datetime "last_synced_at"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "mac_address"
    t.string "model"
    t.string "name"
    t.datetime "rachio_created_at"
    t.string "rachio_id", null: false
    t.string "serial_number"
    t.string "status"
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.index ["rachio_id"], name: "index_controllers_on_rachio_id", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.string "category"
    t.integer "controller_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type"
    t.datetime "occurred_at", null: false
    t.string "rachio_id", null: false
    t.json "raw"
    t.string "sub_type"
    t.text "summary"
    t.datetime "updated_at", null: false
    t.integer "zone_id"
    t.index ["controller_id", "occurred_at"], name: "index_events_on_controller_id_and_occurred_at"
    t.index ["controller_id"], name: "index_events_on_controller_id"
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["rachio_id"], name: "index_events_on_rachio_id", unique: true
    t.index ["zone_id", "occurred_at"], name: "index_events_on_zone_id_and_occurred_at"
    t.index ["zone_id"], name: "index_events_on_zone_id"
  end

  create_table "zones", force: :cascade do |t|
    t.integer "controller_id", null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true
    t.string "image_url"
    t.string "name"
    t.integer "number"
    t.string "rachio_id", null: false
    t.datetime "updated_at", null: false
    t.index ["controller_id"], name: "index_zones_on_controller_id"
    t.index ["rachio_id"], name: "index_zones_on_rachio_id", unique: true
  end

  add_foreign_key "events", "controllers"
  add_foreign_key "events", "zones"
  add_foreign_key "zones", "controllers"
end

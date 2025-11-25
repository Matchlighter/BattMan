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

ActiveRecord::Schema[8.1].define(version: 2025_11_25_144848) do
  create_table "batteries", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "current_device_id"
    t.datetime "updated_at", null: false
    t.index ["current_device_id"], name: "index_batteries_on_current_device_id"
  end

  create_table "devices", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "human_name"
    t.datetime "updated_at", null: false
  end

  create_table "scan_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message"
    t.string "object_id"
    t.string "object_type"
    t.text "payload"
    t.string "scanner_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["object_type", "object_id"], name: "index_scan_logs_on_object"
    t.index ["scanner_id"], name: "index_scan_logs_on_scanner_id"
  end

  create_table "scanners", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "state", default: {}
    t.datetime "updated_at", null: false
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.string "item_id", null: false
    t.string "item_type", null: false
    t.text "object", limit: 1073741823
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "batteries", "devices", column: "current_device_id"
  add_foreign_key "scan_logs", "scanners"
end

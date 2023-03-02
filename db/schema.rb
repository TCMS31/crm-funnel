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

ActiveRecord::Schema[7.0].define(version: 2023_03_10_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "companies", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_companies_on_lower_name", unique: true
    t.index ["created_at", "id"], name: "index_companies_on_recency", order: :desc
  end

  create_table "deal_histories", force: :cascade do |t|
    t.bigint "deal_id", null: false
    t.integer "stage", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deal_id", "created_at", "id"], name: "index_deal_histories_on_deal_and_recency"
    t.index ["deal_id"], name: "index_deal_histories_on_deal_id"
  end

  create_table "deals", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "company_id"
    t.integer "probability", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_deals_on_company_id"
    t.index ["created_at", "id"], name: "index_deals_on_recency", order: :desc
    t.index ["user_id"], name: "index_deals_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.string "email", null: false
    t.string "phone_number"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["created_at", "id"], name: "index_users_on_recency", order: :desc
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "deal_histories", "deals"
  add_foreign_key "deals", "companies"
  add_foreign_key "deals", "users"
  add_foreign_key "users", "companies"
end

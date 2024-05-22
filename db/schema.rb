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

ActiveRecord::Schema[7.1].define(version: 2024_05_22_003451) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "api_batches", force: :cascade do |t|
    t.datetime "completed_at"
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "identities", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.string "handle"
    t.text "image_data"
    t.text "banner_data"
    t.string "image_checksum"
    t.string "banner_checksum"
    t.index ["handle"], name: "index_identities_on_handle", unique: true
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "oauth_credentials", force: :cascade do |t|
    t.bigint "identity_id", null: false
    t.string "provider"
    t.string "token"
    t.string "refresh_token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identity_id"], name: "index_oauth_credentials_on_identity_id", unique: true
  end

  create_table "tweet_metrics", force: :cascade do |t|
    t.integer "retweet_count", default: 0, null: false
    t.integer "like_count", default: 0, null: false
    t.integer "quote_count", default: 0, null: false
    t.integer "impression_count", default: 0, null: false
    t.integer "reply_count", default: 0, null: false
    t.integer "bookmark_count", default: 0, null: false
    t.datetime "pulled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_profile_clicks"
    t.integer "updated_count", default: 0, null: false
    t.bigint "tweet_id"
    t.index ["tweet_id"], name: "index_tweet_metrics_on_tweet_id"
  end

  create_table "tweets", id: :bigint, default: nil, force: :cascade do |t|
    t.text "text", null: false
    t.bigint "identity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "twitter_created_at"
    t.bigint "in_reply_to_status_id"
    t.bigint "api_batch_id"
    t.string "status"
    t.index ["api_batch_id"], name: "index_tweets_on_api_batch_id"
    t.index ["id"], name: "index_tweets_on_id", unique: true
    t.index ["identity_id"], name: "index_tweets_on_identity_id"
    t.index ["in_reply_to_status_id"], name: "index_tweets_on_in_reply_to_status_id"
  end

  create_table "twitter_user_metrics", force: :cascade do |t|
    t.integer "followers_count"
    t.bigint "identity_id", null: false
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identity_id"], name: "index_twitter_user_metrics_on_identity_id"
  end

  create_table "user_twitter_data_updates", force: :cascade do |t|
    t.bigint "identity_id", null: false
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sync_class"
    t.bigint "api_batch_id"
    t.index ["api_batch_id"], name: "index_user_twitter_data_updates_on_api_batch_id"
    t.index ["identity_id"], name: "index_user_twitter_data_updates_on_identity_id"
    t.index ["started_at"], name: "index_user_twitter_data_updates_on_started_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "name"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.string "stripe_customer_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "identities", "users"
  add_foreign_key "oauth_credentials", "identities"
  add_foreign_key "tweet_metrics", "tweets"
  add_foreign_key "tweets", "api_batches"
  add_foreign_key "tweets", "identities"
  add_foreign_key "twitter_user_metrics", "identities"
  add_foreign_key "user_twitter_data_updates", "api_batches"
  add_foreign_key "user_twitter_data_updates", "identities"
end

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

ActiveRecord::Schema[7.1].define(version: 2024_09_02_043013) do
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

  create_table "ad_campaigns", force: :cascade do |t|
    t.string "name"
    t.string "campaign_id"
    t.string "utm_source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_ad_campaigns_on_campaign_id", unique: true
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

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "api_batches", force: :cascade do |t|
    t.datetime "completed_at"
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bug_reports", force: :cascade do |t|
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_bug_reports_on_user_id"
  end

  create_table "content_items", force: :cascade do |t|
    t.text "content", null: false
    t.text "image_data"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_content_items_on_user_id"
  end

  create_table "feature_requests", force: :cascade do |t|
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_feature_requests_on_user_id"
  end

  create_table "identities", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.string "handle"
    t.text "image_data"
    t.text "banner_data"
    t.string "image_checksum"
    t.string "banner_checksum"
    t.boolean "sync_without_user"
    t.boolean "can_dm"
    t.index ["handle"], name: "index_identities_on_handle", unique: true
    t.index ["uid", "provider"], name: "index_identities_on_uid_and_provider", unique: true
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "leaderboard_entries", force: :cascade do |t|
    t.bigint "leaderboard_snapshot_id", null: false
    t.bigint "identity_id", null: false
    t.integer "rank", null: false
    t.integer "impressions", null: false
    t.integer "retweets"
    t.integer "likes"
    t.integer "quotes"
    t.integer "replies"
    t.integer "bookmarks"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identity_id"], name: "index_leaderboard_entries_on_identity_id"
    t.index ["leaderboard_snapshot_id"], name: "index_leaderboard_entries_on_leaderboard_snapshot_id"
  end

  create_table "leaderboard_snapshots", force: :cascade do |t|
    t.date "captured_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mailkick_subscriptions", force: :cascade do |t|
    t.string "subscriber_type"
    t.bigint "subscriber_id"
    t.string "list"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscriber_type", "subscriber_id", "list"], name: "index_mailkick_subscriptions_on_subscriber_and_list", unique: true
  end

  create_table "oauth_credentials", force: :cascade do |t|
    t.bigint "identity_id", null: false
    t.string "provider"
    t.string "token"
    t.string "refresh_token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "secret"
    t.index ["identity_id"], name: "index_oauth_credentials_on_identity_id", unique: true
  end

  create_table "searches", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "keywords", null: false
    t.string "platform", default: "twitter", null: false
    t.datetime "last_searched_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "sent_emails", force: :cascade do |t|
    t.string "recipient", null: false
    t.string "subject", null: false
    t.text "body", null: false
    t.string "tracking_id", null: false
    t.string "email_type", null: false
    t.boolean "opened", default: false
    t.datetime "opened_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["tracking_id"], name: "index_sent_emails_on_tracking_id", unique: true
    t.index ["user_id"], name: "index_sent_emails_on_user_id"
  end

  create_table "sent_posts", force: :cascade do |t|
    t.text "message", null: false
    t.string "post_type", null: false
    t.boolean "sent", default: false
    t.datetime "sent_at"
    t.jsonb "mentioned_users", default: []
    t.string "tracking_id", null: false
    t.integer "channel_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tracking_id"], name: "index_sent_posts_on_tracking_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_subscription_id"
    t.string "stripe_price_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.datetime "current_period_end"
    t.index ["stripe_price_id"], name: "index_subscriptions_on_stripe_price_id"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
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
    t.float "engagement_rate"
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
    t.string "source"
    t.tsvector "searchable"
    t.bigint "search_id"
    t.index ["api_batch_id"], name: "index_tweets_on_api_batch_id"
    t.index ["id"], name: "index_tweets_on_id", unique: true
    t.index ["identity_id"], name: "index_tweets_on_identity_id"
    t.index ["in_reply_to_status_id"], name: "index_tweets_on_in_reply_to_status_id"
    t.index ["search_id"], name: "index_tweets_on_search_id"
    t.index ["searchable"], name: "index_tweets_on_searchable", using: :gin
  end

  create_table "twitter_update_attempts", force: :cascade do |t|
    t.bigint "user_twitter_data_update_id"
    t.string "status"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_twitter_data_update_id"], name: "index_twitter_update_attempts_on_user_twitter_data_update_id"
  end

  create_table "twitter_user_metrics", force: :cascade do |t|
    t.integer "followers_count"
    t.bigint "identity_id", null: false
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "following_count"
    t.integer "listed_count"
    t.index ["identity_id"], name: "index_twitter_user_metrics_on_identity_id"
  end

  create_table "user_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_settings_on_user_id"
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
    t.integer "retry_count", default: 0
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
    t.boolean "enabled_without_subscription", default: false
    t.date "vip_since"
    t.string "otp_secret"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.bigint "ad_campaign_id"
    t.string "ad_campaign"
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

  create_table "votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "votable_type", null: false
    t.bigint "votable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_votes_on_user_id"
    t.index ["votable_type", "votable_id"], name: "index_votes_on_votable"
  end

  add_foreign_key "bug_reports", "users"
  add_foreign_key "content_items", "users"
  add_foreign_key "feature_requests", "users"
  add_foreign_key "identities", "users"
  add_foreign_key "leaderboard_entries", "identities"
  add_foreign_key "leaderboard_entries", "leaderboard_snapshots"
  add_foreign_key "oauth_credentials", "identities"
  add_foreign_key "searches", "users"
  add_foreign_key "sent_emails", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tweet_metrics", "tweets"
  add_foreign_key "tweets", "api_batches"
  add_foreign_key "tweets", "identities"
  add_foreign_key "tweets", "searches"
  add_foreign_key "twitter_update_attempts", "user_twitter_data_updates"
  add_foreign_key "twitter_user_metrics", "identities"
  add_foreign_key "user_settings", "users"
  add_foreign_key "user_twitter_data_updates", "api_batches"
  add_foreign_key "user_twitter_data_updates", "identities"
  add_foreign_key "users", "ad_campaigns"
  add_foreign_key "votes", "users"
end

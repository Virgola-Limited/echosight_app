ActiveAdmin.register TweetMetric do
  actions :index, :show  # Makes the resource read-only

  filter :tweet_identity_user_id, as: :select, collection: -> { User.all.map { |u| [u.email, u.id] } }

  index do
    column :tweet_id
    column :retweet_count
    column :quotes_count
    column :like_count
    column :quote_count
    column :impression_count
    column :reply_count
    column :bookmark_count
    column :pulled_at
    column :created_at
    column :updated_at
    column :user_profile_clicks
    actions
  end

  show do
    attributes_table do
      row :tweet_id
      row :retweet_count
      row :quotes_count
      row :like_count
      row :quote_count
      row :impression_count
      row :reply_count
      row :bookmark_count
      row :pulled_at
      row :created_at
      row :updated_at
      row :user_profile_clicks
    end
  end
end

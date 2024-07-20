ActiveAdmin.register LeaderboardEntry do
  permit_params :leaderboard_snapshot_id, :identity_id, :rank, :impressions, :retweets, :likes, :quotes, :replies, :bookmarks

  index do
    selectable_column
    id_column
    column :leaderboard_snapshot
    column :identity
    column :rank
    column :impressions
    column :retweets
    column :likes
    column :quotes
    column :replies
    column :bookmarks
    column :created_at
    column :updated_at
    actions
  end

  filter :leaderboard_snapshot
  filter :identity
  filter :rank
  filter :impressions
  filter :retweets
  filter :likes
  filter :quotes
  filter :replies
  filter :bookmarks
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs do
      f.input :leaderboard_snapshot
      f.input :identity
      f.input :rank
      f.input :impressions
      f.input :retweets
      f.input :likes
      f.input :quotes
      f.input :replies
      f.input :bookmarks
    end
    f.actions
  end

  show do
    attributes_table do
      row :leaderboard_snapshot
      row :identity
      row :rank
      row :impressions
      row :retweets
      row :likes
      row :quotes
      row :replies
      row :bookmarks
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end

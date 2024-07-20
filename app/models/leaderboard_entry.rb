# == Schema Information
#
# Table name: leaderboard_entries
#
#  id                      :bigint           not null, primary key
#  bookmarks               :integer
#  impressions             :integer          not null
#  likes                   :integer
#  quotes                  :integer
#  rank                    :integer          not null
#  replies                 :integer
#  retweets                :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  identity_id             :bigint           not null
#  leaderboard_snapshot_id :bigint           not null
#
# Indexes
#
#  index_leaderboard_entries_on_identity_id              (identity_id)
#  index_leaderboard_entries_on_leaderboard_snapshot_id  (leaderboard_snapshot_id)
#
# Foreign Keys
#
#  fk_rails_...  (identity_id => identities.id)
#  fk_rails_...  (leaderboard_snapshot_id => leaderboard_snapshots.id)
#
# app/models/leaderboard_entry.rb
class LeaderboardEntry < ApplicationRecord
  belongs_to :leaderboard_snapshot
  belongs_to :identity

  validates :rank, presence: true
  validates :impressions, presence: true
end

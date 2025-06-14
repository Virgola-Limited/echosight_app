# == Schema Information
#
# Table name: leaderboard_snapshots
#
#  id          :bigint           not null, primary key
#  captured_at :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class LeaderboardSnapshot < ApplicationRecord
  has_many :leaderboard_entries, dependent: :destroy

  validates :captured_at, presence: true

  def self.ransackable_associations(auth_object = nil)
    %w[leaderboard_entries]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[captured_at]
  end

  def self.most_recent_snapshot
    order(captured_at: :desc).first
  end

  def rank_for_user(identity)
    return nil unless identity

    entry = leaderboard_entries.where(identity: identity).first
    entry&.rank
  end
end

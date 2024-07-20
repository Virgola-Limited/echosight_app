# == Schema Information
#
# Table name: leaderboard_snapshots
#
#  id          :bigint           not null, primary key
#  captured_at :datetime         not null
#  date_range  :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# app/models/leaderboard_snapshot.rb
class LeaderboardSnapshot < ApplicationRecord
  has_many :leaderboard_entries

  validates :date_range, presence: true
  validates :captured_at, presence: true
end

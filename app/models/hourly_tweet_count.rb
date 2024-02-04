# frozen_string_literal: true

# == Schema Information
#
# Table name: hourly_tweet_counts
#
#  id          :bigint           not null, primary key
#  end_time    :datetime
#  pulled_at   :datetime
#  start_time  :datetime
#  tweet_count :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  identity_id :bigint           not null
#
# Indexes
#
#  index_hourly_tweet_counts_on_identity_id  (identity_id)
#
# Foreign Keys
#
#  fk_rails_...  (identity_id => identities.id)
#
class HourlyTweetCount < ApplicationRecord
  belongs_to :identity
end

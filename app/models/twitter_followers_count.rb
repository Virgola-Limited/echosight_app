# frozen_string_literal: true

# == Schema Information
#
# Table name: twitter_followers_counts
#
#  id              :bigint           not null, primary key
#  date            :date
#  followers_count :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  identity_id     :bigint           not null
#
# Indexes
#
#  index_twitter_followers_counts_on_identity_id  (identity_id)
#
# Foreign Keys
#
#  fk_rails_...  (identity_id => identities.id)
#
class TwitterFollowersCount < ApplicationRecord
  belongs_to :identity
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: twitter_user_metrics
#
#  id              :bigint           not null, primary key
#  date            :date
#  followers_count :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  identity_id     :bigint           not null
#
# Indexes
#
#  index_twitter_user_metrics_on_identity_id  (identity_id)
#
# Foreign Keys
#
#  fk_rails_...  (identity_id => identities.id)
#
FactoryBot.define do
  factory :twitter_user_metric do
    # Define your factory attributes here
    # For example:
    # followers_count { 1000 }
    # user { association(:user) }
  end
end

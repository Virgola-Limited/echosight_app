# == Schema Information
#
# Table name: twitter_update_attempts
#
#  id                          :bigint           not null, primary key
#  error_message               :text
#  status                      :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  user_twitter_data_update_id :bigint
#
# Indexes
#
#  index_twitter_update_attempts_on_user_twitter_data_update_id  (user_twitter_data_update_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_twitter_data_update_id => user_twitter_data_updates.id)
#
class TwitterUpdateAttempt < ApplicationRecord
  belongs_to :user_twitter_data_update
end

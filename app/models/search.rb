# == Schema Information
#
# Table name: searches
#
#  id               :bigint           not null, primary key
#  keywords         :string           not null
#  last_searched_at :datetime
#  platform         :string           default("twitter"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_searches_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
# app/models/search.rb
class Search < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :tweets

  validates :keywords, presence: true
  validates :platform, presence: true, inclusion: { in: %w[twitter threads] }

  enum platform: { twitter: 'twitter', threads: 'threads' }

  def self.ransackable_associations(auth_object = nil)
    %w[user tweets]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[keywords platform user_id]
  end

  def twitter?
    platform == 'twitter'
  end

end

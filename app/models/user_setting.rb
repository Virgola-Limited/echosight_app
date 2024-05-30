# == Schema Information
#
# Table name: user_settings
#
#  id         :bigint           not null, primary key
#  key        :string
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_settings_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
# app/models/user_setting.rb
class UserSetting < ApplicationRecord
  belongs_to :user

  VALID_KEYS = %w[hide_profile_banner].freeze

  SETTINGS = {
    'hide_profile_banner' => {
      default: 'false',
      description: 'Hide the profile banner on the public page',
      on_image: '',
      off_image: ''
    }
  }.freeze

  validates :key, presence: true, uniqueness: { scope: :user_id }, inclusion: { in: VALID_KEYS }
  validates :value, presence: true

  def self.default_value(key)
    SETTINGS[key][:default]
  end

  def self.description(key)
    SETTINGS[key][:description]
  end

  def self.on_image(key)
    SETTINGS[key][:on_image]
  end

  def self.off_image(key)
    SETTINGS[key][:off_image]
  end
end

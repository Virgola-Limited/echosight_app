# frozen_string_literal: true

class UserUpdater
  attr_reader :user_data

  def initialize(user_data)
    @user_data = user_data
  end

  def call
    identity = Identity.find_by!(handle: user_data['username'])
    identity.update!(image_url: user_data['image_url'], banner_url: user_data['banner_url'])
  end
end

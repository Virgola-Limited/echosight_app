# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

def create_follower_count_data(identity_id, start_date, end_date, start_followers, end_followers)
  total_days = (end_date - start_date).to_i
  daily_increment = (end_followers - start_followers) / total_days

  (start_date..end_date).each do |date|
    follower_count = start_followers + (date - start_date).to_i * daily_increment
    TwitterFollowersCount.create!(
      identity_id: identity_id,
      followers_count: follower_count.to_s,
      date: date
    )
  end
end

# Days required in follower seed data
# days_required_in_follower_seed_data = 7.days.ago.to_date
# days_required_in_follower_seed_data = 14.days.ago.to_date unless days_required_in_follower_seed_data
days_required_in_follower_seed_data = 31.days.ago.to_date unless days_required_in_follower_seed_data
days_required_in_follower_seed_data = 60.days.ago.to_date unless days_required_in_follower_seed_data
days_required_in_follower_seed_data = 6.months.ago.to_date unless days_required_in_follower_seed_data
days_required_in_follower_seed_data = 13.months.ago.to_date unless days_required_in_follower_seed_data

if(days_required_in_follower_seed_data && User.count.positive?)
  # Identity ID from the first user's identity
  identity_id = User.first.identity.id
  TwitterFollowersCount.where(identity_id: identity_id).delete_all
  create_follower_count_data(identity_id, days_required_in_follower_seed_data, Date.today, 1000, 1070)
end


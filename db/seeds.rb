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
    TwitterFollowerCount.create!(
      identity_id: identity_id,
      followers_count: follower_count.to_s,
      date: date
    )
  end
end


# Identity ID from the first user's identity
identity_id = User.first.identity.id
TwitterFollowerCount.where(identity_id: identity_id).delete_all
# Generate data for 7 days
# create_follower_count_data(identity_id, 7.days.ago.to_date, Date.today, 1000, 1070)

# Generate data for 14 days
# create_follower_count_data(identity_id, 14.days.ago.to_date, Date.today, 1070, 1140)

# Generate data for 31 days
# create_follower_count_data(identity_id, 31.days.ago.to_date, Date.today, 1140, 1310)

# Generate data for 60 days
# create_follower_count_data(identity_id, 60.days.ago.to_date, Date.today, 1310, 1670)

# Generate data for 6 months
# create_follower_count_data(identity_id, 6.months.ago.to_date, Date.today, 1670, 2670)

# Generate data for more than 12 months
create_follower_count_data(identity_id, 13.months.ago.to_date, Date.today, 2670, 5270)


class PublicPageController < ApplicationController
  def index
       # Initialize the followers_data hash
       followers_data = {}

       # Populate the hash with dummy data for the last 5 years
       1.upto(5) do |year|
         # Calculate the date for 5 years ago plus the year in the loop
         date = 5.years.ago.beginning_of_year.advance(years: year).to_s

         # Calculate a random cumulative number of followers
         followers_data[date] = rand(100..1000) * year
       end

       # Set the instance variables for the view
       @followers_cumulative = followers_data
       @followers_daily = followers_data.transform_values { |v| (v / 5).round }

       # Rest of your index action
  end

  def loftwah
    # Add logic if you need it
  end
end

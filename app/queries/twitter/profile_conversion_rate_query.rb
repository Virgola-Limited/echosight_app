module Twitter
  class ProfileConversionRateQuery
    def conversion_rates_data_for_graph(profile_clicks_data:, followers_data:)
      sorted_dates = (profile_clicks_data.keys + followers_data.keys).uniq.sort
      complete_data = {}

      sorted_dates.each do |date|
        # Skip dates for which there is no data and no previous data to estimate from
        next if (profile_clicks_data[date].nil? && previous_date(profile_clicks_data, date).nil?) ||
                (followers_data[date].nil? && previous_date(followers_data, date).nil?)

        clicks = profile_clicks_data[date] || estimated_value(profile_clicks_data, date)
        followers = followers_data[date] || estimated_value(followers_data, date)
        conversion_rate = clicks > 0 ? (followers.to_f / clicks) * 100 : 0

        complete_data[date] = {
          date: date,
          conversion_rate: conversion_rate,
          followers: followers,
          profile_clicks: clicks
        }
      end

      complete_data.values
    end

    private

    def previous_date(data, current_date)
      data.keys.select { |date| date < current_date }.max
    end

    def estimated_value(data, date)
      prev_date = previous_date(data, date)
      return nil unless prev_date

      # Estimate value based on previous value
      data[prev_date]
    end
  end
end

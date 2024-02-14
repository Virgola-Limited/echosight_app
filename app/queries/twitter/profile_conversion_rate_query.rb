module Twitter

class ProfileConversionRateQuery

  def conversion_rates_data_for_graph(profile_clicks_data:, followers_data:)
    profile_clicks_data.map do |date, clicks|
      followers = followers_data[date] || 0
      conversion_rate = clicks > 0 ? (followers.to_f / clicks) * 100 : 0
      {
        date: date,
        conversion_rate: conversion_rate,
        followers: followers,
        profile_clicks: clicks
      }
    end
  end
end
end
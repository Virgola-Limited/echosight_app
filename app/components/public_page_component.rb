class PublicPageComponent < ViewComponent::Base
  attr_reader :page_data, :page_user, :current_user

  def initialize(page_data:, current_user:)
    @page_data = page_data
    @current_user = current_user
    @page_user = page_data.user
  end

  def page_user_twitter_bio
    helpers.html_description_with_links(page_user.identity.description)
  end

  def method_missing(method_name, *arguments, &block)
    if page_data.respond_to?(method_name)
      page_data.public_send(method_name, *arguments, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    page_data.respond_to?(method_name) || super
  end

  def count_cards
    safe_join([
      posts_card,
      impressions_card,
      likes_card,
      followers_card
    ], "\n")
  end

  private

  def posts_card
    posts_tooltip_text = "This is the total number of tweets you have made in the last #{tweet_comparison_days} days compared to the previous #{tweet_comparison_days} days."
    posts_tooltip_text += "<br /><br />We will continue to collect data so we can show you a whole week compared to the week before" if tweet_comparison_days < 7

    render Shared::MetricsCardComponent.new(
      title: "Posts",
      count: tweet_count_over_available_time_period,
      change: tweets_change_over_available_time_period,
      tooltip_target: "posts-count-tooltip",
      change_text: tweets_change_over_available_time_period.to_s,
      tooltip_text: posts_tooltip_text.html_safe
    )
  end

  def impressions_card
    impressions_tooltip_text = "This is the total number of impressions your posts have made in the last 7 days compared to the previous 7 days."
    impressions_tooltip_text += "<br /><br />We will continue to collect data so we can show you a whole week compared to the week before" if impressions_comparison_days < 7

    render Shared::MetricsCardComponent.new(
      title: "Impressions",
      count: impressions_count,
      change: impressions_change_since_last_week,
      tooltip_target: "impressions-count-tooltip",
      change_text: impressions_change_since_last_week.to_s,
      tooltip_text: impressions_tooltip_text.html_safe
    )
  end

  def likes_card
    likes_tooltip_text = "This is the total number of likes you've received in the last #{likes_comparison_days} days. Compared to the previous #{likes_comparison_days} days."
    likes_tooltip_text += "<br /><br />We will continue to collect data so we can show you a whole week compared to the week before" if likes_comparison_days < 7

    render Shared::MetricsCardComponent.new(
      title: "Likes",
      count: likes_count,
      change: likes_change_since_last_week,
      tooltip_target: "likes-count-tooltip",
      change_text: likes_change_since_last_week.to_s,
      tooltip_text: likes_tooltip_text.html_safe
    )
  end

  def followers_card
    followers_tooltip_text = "This is the total number of followers you have acquired in the last #{followers_comparison_days} days compared to the previous #{followers_comparison_days} days."
    followers_tooltip_text += "<br /><br />We will continue to collect data so we can show you a whole week compared to the week before" if followers_comparison_days < 7

    render Shared::MetricsCardComponent.new(
      title: "Followers",
      count: followers_count,
      change: followers_count_change_percentage_text,
      tooltip_target: "followers-count-tooltip",
      change_text: followers_count_change_percentage_text.to_s,
      tooltip_text: followers_tooltip_text.html_safe
    )
  end

end
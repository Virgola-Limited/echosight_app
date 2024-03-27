class PublicPageComponent <  ApplicationComponent
  attr_reader :public_page_data, :page_user, :current_user

  def initialize(public_page_data:, current_user:)
    @public_page_data = public_page_data
    @current_user = current_user
    @page_user = public_page_data.user
  end

  def page_user_handle
    page_user&.handle || "demo_user"
  end

  def page_user_name
    page_user&.name || "Demo User"
  end

  def page_user_banner_url
    page_user&.identity&.banner_url
  end

  def page_user_twitter_bio
    helpers.html_description_with_links(user_description)
  end

  def method_missing(method_name, *arguments, &block)
    if public_page_data.respond_to?(method_name)
      public_page_data.public_send(method_name, *arguments, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    public_page_data.respond_to?(method_name) || super
  end

  def count_cards
    safe_join([
      posts_card,
      impressions_card,
      likes_card,
      followers_card
    ], "\n")
  end

  def render_twitter_image(image_class)
    image_tag_html = if page_user&.image_url.present?
                       helpers.image_tag(page_user&.image_url, alt: "#{page_user&.handle} Profile image", class: image_class)
                     else
                       helpers.vite_image_tag("images/twitter-default-avatar.png", class: image_class)
                     end

    if twitter_link
      helpers.link_to(twitter_link, target: "_blank") { image_tag_html }.html_safe
    else
      image_tag_html
    end
  end

  private

  def twitter_link
    page_user&.handle.present? ? "https://twitter.com/#{page_user&.handle}" : nil
  end

  def user_description
    page_user&.identity&.description || "Amplify your digital impact with Echosight"
  end

  def posts_card
    render Shared::MetricsCardComponent.new(
      title: "Posts",
      count: tweet_count_over_available_time_period,
      change_text: tweets_change_over_available_time_period,
      tooltip_target: "posts-count-tooltip",
      tooltip_text: posts_tooltip_text.html_safe
    )
  end

  def posts_tooltip_text
    if days_of_data_in_recent_count < 7
      # For 7 days or less of recent data
      posts_tooltip_text = "This is the total number of tweets you have made in the last #{days_of_data_in_recent_count} days."
      posts_tooltip_text += " We will continue to collect data to provide more comprehensive insights."
    elsif days_of_data_in_difference_count < 7
      # For less than 7 days of data in the difference count
      posts_tooltip_text = "This is the total number of tweets you have made in the last 7 days compared to the previous period."
      posts_tooltip_text += " We are still collecting data to show a full week comparison."
    else
      # After having 14 days of data
      posts_tooltip_text = "This is the total number of tweets you have made in the last 7 days compared to the previous 7 days."
    end

    posts_tooltip_text
  end

  def impressions_card
    impressions_tooltip_text = "This is the total number of impressions your posts have made in the last 7 days compared to the previous 7 days."
    impressions_tooltip_text += "<br /><br />We will continue to collect data so we can show you a whole week compared to the week before" if impressions_comparison_days < 7

    render Shared::MetricsCardComponent.new(
      title: "Impressions",
      count: impressions_count,
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
      tooltip_target: "followers-count-tooltip",
      change_text: followers_count_change_percentage_text.to_s,
      tooltip_text: followers_tooltip_text.html_safe
    )
  end

end
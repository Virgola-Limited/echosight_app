module ApplicationHelper
  include ActionView::Helpers::UrlHelper

  def html_description_with_links(description)
    description.to_s.gsub(%r{(https?://[^\s]+)}) do |url|
      uri = URI.parse(url)
      host_and_path = uri.host + uri.path.chomp('/')

      # Use the full URL for the href, and the simplified URL for display
      link_to(host_and_path, url, target: '_blank', rel: 'noopener noreferrer')
    end.html_safe
  end

  def rounded_number(input)
    NumberRoundingService.call(input)
  end

  def render_twitter_image(image_class, user)
    image_tag_html = if user&.image_url.present?
                       image_tag(user&.image_url, alt: "#{user&.handle} Profile image", class: image_class)
                     else
                       vite_image_tag("images/twitter-default-avatar.png", class: image_class)
                     end

    image_tag_html
  end

end

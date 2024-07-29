# app/helpers/application_helper.rb
module ApplicationHelper

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
    image_url = if user.is_a?(Hash)
                  image_data = user[:image_data].is_a?(String) ? JSON.parse(user[:image_data]) : user[:image_data]
                  generate_shrine_image_url(image_data)
                elsif user.respond_to?(:image_url)
                  user.image_url
                elsif user&.identity&.image_url
                  user.identity.image_url
                else
                  nil
                end
    handle = user.is_a?(Hash) ? user[:handle] : user.handle
    image_tag_html = if image_url.present?
                       image_tag(image_url, alt: "#{handle} Profile image", class: image_class)
                     else
                       vite_image_tag("images/twitter-default-avatar.png", class: image_class)
                     end

    image_tag_html
  end

  private

  def generate_shrine_image_url(image_data)
    storage_key = image_data['storage']
    file_id = image_data['id']

    Shrine.storages[storage_key.to_sym].url(file_id)
  end
end

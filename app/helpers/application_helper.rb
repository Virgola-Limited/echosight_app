# app/helpers/application_helper.rb
module ApplicationHelper
  def html_description_with_links(description)
    description.to_s.gsub(%r{(https?://[^\s]+)}) do |url|
      uri = URI.parse(url)
      host_and_path = uri.host + uri.path.chomp('/')
      link_to(host_and_path, url, target: '_blank', rel: 'noopener noreferrer')
    end.html_safe
  end

  def rounded_number(input)
    NumberRoundingService.call(input)
  end

  def render_twitter_image(image_class, user)
    image_url = get_image_url(user)
    handle = get_handle(user)

    if image_url.present?
      image_tag(image_url, alt: "#{handle} Profile image", class: image_class)
    else
      vite_image_tag("images/twitter-default-avatar.png", alt: "Default Profile image", class: image_class)
    end
  end

  private

  def get_image_url(user)
    case user
    when Hash
      generate_shrine_image_url(parse_image_data(user[:image_data]))
    when ->(u) { u.respond_to?(:image_url) }
      user.image_url
    when ->(u) { u&.identity&.image_url }
      user.identity.image_url
    else
      nil
    end
  end

  def get_handle(user)
    user.is_a?(Hash) ? user[:handle] : user.handle
  end

  def parse_image_data(image_data)
    image_data.is_a?(String) ? JSON.parse(image_data) : image_data
  end

  def generate_shrine_image_url(image_data)
    return nil if image_data.blank? || !image_data.is_a?(Hash) || image_data['storage'].blank? || image_data['id'].blank?

    storage_key = image_data['storage']
    file_id = image_data['id']

    begin
      Shrine.storages[storage_key.to_sym].url(file_id)
    rescue StandardError => e
      Rails.logger.error "Error generating Shrine image URL: #{e.message}"
      nil
    end
  end
end
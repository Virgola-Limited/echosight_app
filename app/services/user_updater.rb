# frozen_string_literal: true

class UserUpdater
  attr_reader :user_data

  def initialize(user_data)
    @user_data = user_data
  end

  def call
    raise ArgumentError, "User data must include image_url and banner_url: #{user_data}" if user_data['image_url'].nil? || user_data['banner_url'].nil?

    identity = Identity.find_by!(handle: user_data['username'])
    updated_image_url = transform_image_url(user_data['image_url'])
    identity.update!(image_url: updated_image_url, banner_url: user_data['banner_url'])
  end

  private

  def transform_image_url(url)
    if image_link?(url.gsub('_normal', '_400x400'))
      url.gsub('_normal', '_400x400')
    else
      raise '400x400 image not found, using original URL.'
      url
    end
  end

  def image_link?(url)
    uri = URI.parse(url)
    use_ssl = uri.scheme == 'https'

    Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl, open_timeout: 5, read_timeout: 5) do |http|
      response = http.request_head(uri.path.blank? ? '/' : uri.path)

      # Handling redirects, considering only a single redirect for simplicity
      if response.code.to_i >= 300 && response.code.to_i < 400 && response['location'].present?
        return image_link?(response['location'])
      end

      response.content_type&.start_with?('image/')
    end
  rescue => e
    Rails.logger.error("Error checking image link: #{e.message}")
    false
  end
end

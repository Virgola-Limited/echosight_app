# frozen_string_literal: true

class UserUpdater
  attr_reader :user_data

  def initialize(user_data)
    @user_data = user_data
  end

  def call
    raise ArgumentError, "User data must include image_url and banner_url: #{user_data}" if user_data['image_url'].nil? || user_data['banner_url'].nil?

    identity = Identity.find_by!(handle: user_data['username'])

    identity.image = download_image(transform_image_url(user_data['image_url']))
    identity.banner = download_image(transform_banner_url(user_data['banner_url']))
    identity.save!
  end

  private

  def download_image(url)
    return URI.open(url)
  end

  def transform_banner_url(url)
    url + '/1500x500'
  end

  def transform_image_url(url)
    if image_link?(url.gsub('_normal', '_400x400'))
      url.gsub('_normal', '_400x400')
    else
      ExceptionNotifier.notify_exception(StandardError.new('400x400 image not found, using original URL.'), data: url.gsub('_normal', '_400x400'))
      url
    end
  end

  def image_link?(url)
    uri = URI.parse(url)
    use_ssl = uri.scheme == 'https'

    Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl, open_timeout: 5, read_timeout: 5) do |http|
      response = http.request_head(uri.path.blank? ? '/' : uri.path)

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

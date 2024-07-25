# frozen_string_literal: true

# Might need to be namespaces to Twitter when we have Threads
class IdentityUpdater
  require 'digest'
  attr_reader :user_data


  def initialize(user_data)
    @user_data = user_data
  end

  def call
    identity = Identity.twitter.where(uid: user_data['id']).first
    raise "Identity not found for user: #{user_data['username']} #{user_data['id']}" unless identity

    if user_data['image_url']
      transformed_image_url = transform_image_url(user_data['image_url'])
      new_image_checksum = checksum(transformed_image_url)
      if identity.image_checksum != new_image_checksum
        identity.image = download_image(transformed_image_url)
        identity.image_checksum = new_image_checksum
      end
    end

    if user_data['banner_url']
      transformed_banner_url = transform_banner_url(user_data['banner_url'])
      new_banner_checksum = checksum(transformed_banner_url)
      if identity.banner_checksum != new_banner_checksum
        identity.banner = download_image(transformed_banner_url)
        identity.banner_checksum = new_banner_checksum
      end
    end

    identity.handle = user_data['username']
    identity.description = UrlRewriter.new(user_data['description']).call if user_data['description']
    identity.can_dm = user_data['can_dm']
    identity.save!
  end

  private

  def download_image(url)
    URI.open(url)
  end

  def transform_banner_url(url)
    "#{url}/1500x500"
  end

  def transform_image_url(url)
    modified_url = url.gsub('_normal', '_400x400')
    if image_link?(modified_url)
      modified_url
    else
      ExceptionNotifier.notify_exception(StandardError.new('400x400 image not found, using original URL.'), data: modified_url)
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

  def checksum(url)
    data = URI.open(url).read
    Digest::SHA256.hexdigest(data)
  end
end

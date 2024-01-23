module LinkHelper
  def link_to(name = nil, options = nil, html_options = {}, &block)
    if html_options[:class].nil? || html_options[:class].empty?
      html_options[:class] = "text-primary-700 hover:underline dark:text-primary-500"
    end
    super
  end

  def text_with_images(text)
    processed_text = text.dup
    processed_text.gsub!(URI.regexp(['http', 'https'])) do |url|
      Rails.logger.debug('paul' + url.inspect)
      if image_link?(url)
        "<img src='#{url}' alt='Tweet Image' style='max-width:100%;'/>"
      else
        link_to(url, url, target: "_blank")
      end
    end
    processed_text.html_safe
  end

  private

  ###########################################################
  # MVP: SUPER SLOW DO NOT USE IN PRODUCTION
  # TODO need to background this before we go into production
  ###########################################################
  def image_link?(url, limit = 10)
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    response = http.request_head(uri.path.empty? ? "/" : uri.path)
    Rails.logger.debug('paul response' + response.inspect)
    case response
    when Net::HTTPSuccess then
      response.content_type.start_with?('image/')
    when Net::HTTPRedirection then
      new_uri = URI.join(url, response['location']).to_s
      image_link?(new_uri, limit - 1)
    else
      false
    end
  rescue => e
    Rails.logger.error("Error checking image link: #{e.message}")
    false
  end
end

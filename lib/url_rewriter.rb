class UrlRewriter
  def initialize(text)
    @text = text
  end

  def call
    URI.extract(@text).each do |url|
      url_without_trailing_slash = url.chomp('/')
      original_url = resolve_url(url_without_trailing_slash)
      @text.gsub!(url, original_url || url)
    end
    @text
  end

  private

  def resolve_url(short_url)
    uri = URI(short_url)
    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPRedirection then
      response['location']
    else
      nil
    end
  rescue
    short_url
  end
end

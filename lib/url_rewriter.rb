class UrlRewriter
  def initialize(text)
    @text = text
  end

  def call
    URI.extract(@text).each do |url|
      original_url = resolve_url(url)
      @text.gsub!(url, original_url) if original_url
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
  end
end
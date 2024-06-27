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

end

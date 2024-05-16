module ApplicationHelper
  include ActionView::Helpers::UrlHelper

  def number_to_human_readable(number)
    if number >= 1_000_000
      "#{(number / 1_000_000.0).round(2)}M"
    elsif number >= 1_000
      "#{(number / 1_000.0).round(2)}K"
    else
      number.to_s
    end
  end

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

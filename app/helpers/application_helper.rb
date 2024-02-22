module ApplicationHelper
  include ActionView::Helpers::UrlHelper

  def html_description_with_links(description)
    description.to_s.gsub(/(https?:\/\/[^\s]+)/) do |url|
      link_to(url, url, target: '_blank', rel: 'noopener noreferrer')
    end.html_safe
  end
end

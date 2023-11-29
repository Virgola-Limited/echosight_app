module LinkHelper
  def link_to(name = nil, options = nil, html_options = {}, &block)
    if html_options[:class].nil? || html_options[:class].empty?
      html_options[:class] = "text-primary-700 hover:underline dark:text-primary-500"
    end
    super
  end
end

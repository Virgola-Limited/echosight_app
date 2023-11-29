module LinkHelper
  def link_to(name = nil, options = nil, html_options = {}, &block)
    html_options[:class] = [html_options[:class], "text-primary-700 hover:underline dark:text-primary-500"].compact.join(' ')
    super
  end
end

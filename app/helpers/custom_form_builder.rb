# app/helpers/custom_form_builder.rb
class CustomFormBuilder < ActionView::Helpers::FormBuilder
  def initialize(object_name, object, template, options)
    options[:html] ||= {}
    options[:html][:class] = default_form_classes(options[:html][:class])
    super
  end

  def label(method, text = nil, options = {}, &block)
    options[:class] ||= 'block mb-2 text-sm font-medium text-gray-900 dark:text-white'
    super(method, text, options, &block)
  end

  def text_field(method, options = {})
    super(method, class: default_input_classes(options))
  end

  def password_field(method, options = {})
    super(method, class: default_input_classes(options))
  end

  def email_field(method, options = {})
    super(method, class: default_input_classes(options))
  end

  # ... any other field types you want to customize ...

  private

  def default_form_classes(existing_classes)
    default_classes = 'mt-8 space-y-6'
    [existing_classes, default_classes].compact.join(' ')
  end

  def default_input_classes(options)
    default_classes = 'bg-gray-50 border border-gray-300 text-gray-900 sm:text-sm rounded-lg focus:ring-primary-500 focus:border-primary-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-primary-500 dark:focus:border-primary-500'
    [options[:class], default_classes].compact.join(' ')
  end
end

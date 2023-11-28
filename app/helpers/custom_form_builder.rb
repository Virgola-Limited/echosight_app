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

  def submit(value=nil, options={})
    options[:class] ||= submit_default_classes
    super(value, options)
  end

  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    options[:class] ||= checkbox_default_classes
    super(method, options, checked_value, unchecked_value)
  end

  private

  def checkbox_default_classes
    'w-4 h-4 border-gray-300 rounded bg-gray-50 focus:ring-3 focus:ring-primary-300 dark:focus:ring-primary-600 dark:ring-offset-gray-800 dark:bg-gray-700 dark:border-gray-600'
  end

  def submit_default_classes
    'w-full px-5 py-3 text-base font-medium text-center text-white bg-primary-700 rounded-lg hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 sm:w-auto dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800'
  end

  def default_form_classes(existing_classes)
    default_classes = 'mt-8 space-y-6'
    [existing_classes, default_classes].compact.join(' ')
  end

  def default_input_classes(options)
    default_classes = 'bg-gray-50 border border-gray-300 text-gray-900 sm:text-sm rounded-lg focus:ring-primary-500 focus:border-primary-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-primary-500 dark:focus:border-primary-500'
    [options[:class], default_classes].compact.join(' ')
  end
end

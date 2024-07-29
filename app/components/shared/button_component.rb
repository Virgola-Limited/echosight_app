module Shared
  class ButtonComponent < ApplicationComponent
    def initialize(text:, url: nil, classes: nil, method: :get, in_form: false, no_form: false, size: :base)
      @text = text
      @url = url
      @classes = classes
      @method = method
      @in_form = in_form
      @no_form = no_form
      @size = size
    end

    def call
      render_button
    end

    private

    def classes
      "#{size_classes} #{@classes} font-medium text-center transition duration-150 ease-in-out text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
    end

    def size_classes
      case @size
      when :extra_small
        "px-3 py-2 text-xs"
      when :small
        "px-3 py-2 text-sm"
      when :base
        "px-5 py-2.5 text-sm"
      when :large
        "px-5 py-3 text-base"
      when :extra_large
        "px-6 py-3.5 text-base"
      else
        "px-5 py-2.5 text-sm"
      end
    end

    def render_button
      if @no_form
        link_to @url, class: classes, data: { controller: 'debounce', button_target: 'button', original_text: @text, turbo: false } do
          @text
        end
      elsif @in_form
        tag.button type: 'submit', class: classes, data: { controller: 'debounce', button_target: 'button', original_text: @text, action: 'click->debounce#handleClick' } do
          @text
        end
      else
        form_with url: @url, method: @method, data: { turbo: false } do
          tag.button type: 'submit', class: classes, data: { controller: 'debounce', button_target: 'button', original_text: @text, action: 'click->debounce#handleClick' } do
            @text
          end
        end
      end
    end
  end
end

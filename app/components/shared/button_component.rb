module Shared
  class ButtonComponent < ApplicationComponent
    def initialize(text:, url: nil, classes: nil, method: :post, in_form: false, no_form: false)
      @text = text
      @url = url
      @classes = classes
      @method = method
      @in_form = in_form
      @no_form = no_form
    end

    def call
      render_button
    end

    private

    def classes
      "#{@classes} px-5 py-3 text-base font-medium text-center text-blue-100 transition duration-150 ease-in-out bg-blue-500 rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-4 focus:ring-blue-300"
    end

    def render_button
      if @no_form
        tag.button type: 'button', class: classes, data: { controller: 'debounce', button_target: 'button', original_text: @text } do
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

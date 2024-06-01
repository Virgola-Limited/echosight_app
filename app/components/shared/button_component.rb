module Shared
  class ButtonComponent < ApplicationComponent
    def initialize(text:, url:, classes: nil, method: :post, in_form: false)
      @text = text
      @url = url
      @classes = classes
      @method = method
      @in_form = in_form
    end

    def call
      render_button
    end

    private

    def classes
      "#{@classes} px-5 py-3 text-base font-medium text-center text-blue-100 transition duration-150 ease-in-out bg-blue-500 rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-4 focus:ring-blue-300"
    end

    def render_button
      if @in_form
        tag.button type: 'submit', class: classes, data: { controller: 'button', button_target: 'button', original_text: @text } do
          @text
        end
      else
        form_with url: @url, method: @method, data: { turbo: false } do
          tag.button type: 'submit', class: classes, data: { controller: 'button', button_target: 'button', original_text: @text } do
            @text
          end
        end
      end
    end
  end
end

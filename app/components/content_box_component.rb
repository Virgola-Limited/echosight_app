# frozen_string_literal: true

class ContentBoxComponent < ApplicationComponent

  def call
    content_tag :div, class: 'w-full space-y-4 p-4 bg-white rounded-lg shadow dark:bg-gray-800 mb-4' do
      content
    end
  end

end
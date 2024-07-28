# frozen_string_literal: true

class PrimaryActionButtonComponent < ApplicationComponent
  attr_reader :user, :url, :link_text, :button_classes

  def initialize(user:, url: nil)
    @user = user
    @url = url
    @link_text = button_text.sample
  end

  def before_render
    @url ||= button_url
  end

  def call
    link_to @url do
      render Shared::ButtonComponent.new(
        text: @link_text,
        url: @url,
        classes: responsive_classes,
        no_form: true
      )
    end
  end

  private

  def button_text
    return ['Dashboard'] unless user.guest?
    [
      'Get Your Personal Stats Dashboard',
      'Start Tracking Your Twitter/X Impact'
    ]
  end

  def button_url
    return dashboard_index_path unless user.guest?
    new_user_registration_path
  end

  def responsive_classes
    "md:px-3 md:py-2 md:text-sm lg:px-5 lg:py-3 lg:text-base"
  end
end

# frozen_string_literal: true

class PrimaryActionButtonComponent <  ApplicationComponent
  attr_reader :user, :url, :link_text

  # TODO Paid users can disable the button on their profile page so no button shows
  def initialize(user:, url: nil)
    @user = user
    @link_text = button_text.sample
    super
  end

  def before_render
    @url ||= button_url
  end

  private

  # could rotate the text on the button (like Netflix does with the tv show images)
  def button_text
    return ['Dashboard'] unless user.guest?
    # From ChatGTP:
    [
      'Get Your Personal Stats Dashboard',
      'Start Tracking Your Twitter/X Impact',
      'Launch Your Twitter/X Analytics',
      'Unveil Your Twitter/X Insights',
      'Build Your Twitter/X Stats Page'
    ]
  end

  def button_url
    return dashboard_index_path unless user.guest?
    new_user_registration_path
  end
end

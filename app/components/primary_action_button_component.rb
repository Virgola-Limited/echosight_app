# frozen_string_literal: true

class PrimaryActionButtonComponent < ApplicationComponent
  attr_reader :user, :url, :link_text, :request

  def initialize(user:, request:, url: nil)
    @user = user
    @request = request
    @url = url
    @link_text = determine_button_text
  end

  def before_render
    @url ||= determine_button_url
  end

  def call
    render Shared::ButtonComponent.new(
      text: @link_text,
      url: @url,
      classes: 'w-full sm:flex md:block',
      no_form: true,
      size: :extra_small,
      method: :get
    )
  end

  private

  def determine_button_text
    if show_login_button?
      'Login'
    elsif user.guest?
      button_text.sample
    else
      'Dashboard'
    end
  end

  def determine_button_url
    if show_login_button?
      new_user_session_path
    elsif user.guest?
      new_user_registration_path
    else
      dashboard_index_path
    end
  end

  def show_login_button?
    [
      '/users/sign_up',
      '/users/password/new',
      '/users/confirmation/new'
    ].include?(request.path)
  end

  def button_text
    [
      'Get Your Personal Stats Dashboard',
      'Start Tracking Your Twitter/X Impact'
    ]
  end
end
require 'rails_helper'

RSpec.feature 'Dark Mode Toggle', type: :feature, js: true do
  let(:user) { create(:user) }

  scenario 'toggle dark mode on login page' do
    visit new_user_session_path

    theme_toggle = find('#theme-toggle')
    theme_toggle_dark_icon = find('#theme-toggle-dark-icon', visible: false)
    theme_toggle_light_icon = find('#theme-toggle-light-icon', visible: false)

    # Initially, dark mode should be enabled
    expect(theme_toggle_light_icon[:class]).not_to include('hidden')
    expect(theme_toggle_dark_icon[:class]).to include('hidden')
    expect(page).to have_css('html.dark')

    # Toggle to light mode
    theme_toggle.click
    expect(theme_toggle_light_icon[:class]).to include('hidden')
    expect(theme_toggle_dark_icon[:class]).not_to include('hidden')
    expect(page).not_to have_css('html.dark')

    # Toggle back to dark mode
    theme_toggle.click
    expect(theme_toggle_light_icon[:class]).not_to include('hidden')
    expect(theme_toggle_dark_icon[:class]).to include('hidden')
    expect(page).to have_css('html.dark')
  end

  scenario 'toggle dark mode on new subscription page' do
    login_user(user)
    visit new_subscription_path

    theme_toggle = find('#theme-toggle')
    theme_toggle_dark_icon = find('#theme-toggle-dark-icon', visible: false)
    theme_toggle_light_icon = find('#theme-toggle-light-icon', visible: false)

    # Initially, dark mode should be enabled
    expect(theme_toggle_light_icon[:class]).not_to include('hidden')
    expect(theme_toggle_dark_icon[:class]).to include('hidden')
    expect(page).to have_css('html.dark')

    # Toggle to light mode
    theme_toggle.click
    expect(theme_toggle_light_icon[:class]).to include('hidden')
    expect(theme_toggle_dark_icon[:class]).not_to include('hidden')
    expect(page).not_to have_css('html.dark')

    # Toggle back to dark mode
    theme_toggle.click
    expect(theme_toggle_light_icon[:class]).not_to include('hidden')
    expect(theme_toggle_dark_icon[:class]).to include('hidden')
    expect(page).to have_css('html.dark')
  end
end

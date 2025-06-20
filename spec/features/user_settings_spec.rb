require 'rails_helper'

RSpec.feature 'User Settings Page' do
  scenario 'Toggle User Settings' do
    # TODO: Doesnt work on CI fix later
    unless ENV['CI']
      user = create(:user)
      setting_key = UserSetting::VALID_KEYS.first
      create(:user_setting, user: user, key: setting_key, value: 'false')

      login_as(user, scope: :user)
      visit edit_user_settings_path

      # Toggle setting on
      find("label[for='user_settings_#{setting_key}']").click

      # Wait for the setting to be updated via AJAX
      expect(page).to have_checked_field("user_settings[#{setting_key}]")
      visit edit_user_settings_path
      expect(find("input[name='user_settings[#{setting_key}]']")).to be_checked

      # Ensure the element is present and interactable
      expect(page).to have_selector("label[for='user_settings_#{setting_key}']", visible: true)

      # Toggle setting off
      find("label[for='user_settings_#{setting_key}']").click

      # Wait for the setting to be updated via AJAX
      expect(page).to have_unchecked_field("user_settings[#{setting_key}]")

      visit edit_user_settings_path
      expect(find("input[name='user_settings[#{setting_key}]']")).not_to be_checked
    end
  end
end

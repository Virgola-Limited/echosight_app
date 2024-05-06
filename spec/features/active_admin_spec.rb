require 'rails_helper'

RSpec.describe 'Active Admin navigation links', type: :feature do
  let(:admin_user) { create(:admin_user) }

  before do
    login_as admin_user, scope: :admin_user
    visit admin_root_path
  end

  it 'loads all top menu links without errors' do
    # First, collect all the links
    links = all('#tabs .menu_item a').map { |link| [link[:href], link.text] }
    expect(links.count).to be > 5
    # Then visit each link, ignoring the 'sidekiq' link
    links.each do |href, text|
      next if text == 'sidekiq'
      visit href
      expect(page).not_to have_content('404')
      expect(page).not_to have_content('500')
      # Add additional checks as necessary
    end
  end
end

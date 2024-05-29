require 'rails_helper'

RSpec.describe 'Active Admin navigation links' do
  let(:admin_user) { create(:admin_user) }

  before do
    login_as admin_user, scope: :admin_user
    visit admin_root_path
  end

  def links
    all('#tabs .menu_item a').map { |link| [link[:href], link.text.strip] }.reject { |href, text| text == 'PgHero' || text == 'Sidekiq'}
  end

  it 'loads all top menu links without errors' do
    expect(links.count).to be > 5

    links.each do |href, text|
      visit href
      expect(page).not_to have_content('404')
      expect(page).not_to have_content('500')
    end
  end

  it 'redirects to login page if not logged in' do
    logout(:admin_user)

    links.each do |href, _text|
      visit href
      expect(current_path).to eq(new_admin_user_session_path)
    end
  end
end

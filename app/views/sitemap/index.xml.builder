xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.urlset xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9' do
  # Static URLs
  static_urls = [
    root_url,                      # Home page
    new_user_registration_url,     # Sign-up page (Devise)
    new_user_session_url           # Sign-in page (Devise)
  ]

  static_urls.each do |url|
    xml.url do
      xml.loc url
      xml.lastmod Time.current.strftime('%Y-%m-%d')
    end
  end

  # Syncable user URLs
  @users.each do |user|
    xml.url do
      xml.loc public_page_url(handle: user.identity.handle)
      xml.lastmod user.updated_at.strftime('%Y-%m-%d')
    end
  end
end

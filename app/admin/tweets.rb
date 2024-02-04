ActiveAdmin.register Tweet do
  actions :index

  index do
    column :id
    column "Tweet" do |tweet|
      link_to tweet.text.truncate(50), "https://twitter.com/#{tweet.identity.handle}/status/#{tweet.twitter_id}", target: "_blank"
    end
    column :created_at
    column :updated_at
    actions
  end
end

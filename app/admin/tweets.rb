ActiveAdmin.register Tweet do
  actions :index

  index do
    column :id
    column "Tweet" do |tweet|
      link_to tweet.text.truncate(50), "https://twitter.com/#{tweet.identity.handle}/status/#{tweet.twitter_id}", target: "_blank"
    end
    column "User Email" do |tweet|
      if tweet.identity && tweet.identity.user
        link_to tweet.identity.user.email, admin_user_path(tweet.identity.user)
      else
        "No User"
      end
    end
    column :created_at
    column :updated_at
    actions
  end
end

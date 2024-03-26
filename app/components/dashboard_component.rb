# Rules to confirm with Dean about dashboard not button.
# A. On own public page (not frequent)
# 1. Logged In Paid user:  button will show a link to the dashboard?
# 2. Logged In Trial User: button will show a link to subscription page?
# 3. Not logged in: button will show link to "Want one of these"?

# B. On someone elses public page
# 1. Logged In Paid user: Perhaps show nothing as its a bit confusing linking to your dashboard from someone else's public page?
# 2. Logged In Trial User: button will show a link to subscription page? Think about the copy -
# 3. Not logged in: button will show link to "get their public page"?

# C. On dashboard page
# 1. Logged In Paid user: Share Echosight? )(make it clear its not sharing their dashboard values)
# 2. Logged In Trial User: button will show a link to subscription page?
# 3. Logged In with no trial or active subscription:
# a: Could have a link to a 7 days free trial (if they havent had one recently)
# b: Otherwise link to subscription page?

# Missing steps message

# Check with Dean but we need to show steps to get their public page working

# 1. Need to connect to Twitter
# 2. Need to supply their email address if they logged in with Twitter/X as Twitter/X wont give it to user
# 3. Need to have a paid subscription

class DashboardComponent < ApplicationComponent
  def initialize(current_user:)
    @current_user = current_user
  end

  private

  attr_reader :current_user
end

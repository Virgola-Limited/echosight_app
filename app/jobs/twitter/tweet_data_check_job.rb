module Twitter
  class TweetDataCheckJob
    include Sidekiq::Job
    sidekiq_options retry: false, queue: 'low_priority'

    def perform
      check_and_notify(Twitter::TweetDataChecksQuery.incomplete_user_updates(3, "Incomplete User Updates")
      check_and_notify(Twitter::TweetDataChecksQuery.problematic_tweets, "Tweets with First Metric Issues")
      check_and_notify(Twitter::TweetDataChecksQuery.tweets_needing_refresh, "Tweets Needing Refresh")
    end

    private

    def check_and_notify(query_result, issue_type)
      if query_result.any?
        message = "There are issues with #{issue_type}. Please check the dashboard for more details."
        Notifications::SlackNotifier.call(message: message, channel: :general)
      end
    end
  end
end

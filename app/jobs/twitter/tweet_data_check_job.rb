module Twitter
  class TweetDataCheckJob
    include Sidekiq::Job
    sidekiq_options retry: 3, queue: 'data_integrity'

    def perform
      check_and_notify(Twitter::TweetDataQuery.incomplete_user_updates(Twitter::NewTweetsFetcher.days_to_fetch), "Incomplete User Updates")
      check_and_notify(Twitter::TweetDataQuery.problematic_tweets, "Problematic Tweets")
      check_and_notify(Twitter::TweetDataQuery.tweets_needing_refresh(Twitter::NewTweetsFetcher.days_to_fetch), "Tweets Needing Refresh")
      # check_and_notify(Twitter::TweetDataQuery.aggregated_metrics, "Aggregated Metrics Issues")
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

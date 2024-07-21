# app/services/twitter/leaderboard_notification_service.rb
module Twitter
  class LeaderboardNotificationService
    def initialize
      @queries = [
        { query: Twitter::Leaderboard::LeaderChangeQuery.new, message_method: :leader_change_message },
        { query: Twitter::Leaderboard::NewTopTenEntriesQuery.new, message_method: :new_top_ten_entries_message }
      ]
    end

    def run
      @queries.each do |query_config|
        result = query_config[:query].call
        next unless result

        message = send(query_config[:message_method], result)
        puts "Debug: Generated message - #{message}" # Debugging line
        send_notification(message)
      end
    end

    private

    def leader_change_message(result)
      new_leader_handle = result[:new_leader][:twitter_handle]
      leaders_list = result[:leaders_list] || ""
      "Congratulations @#{new_leader_handle} on topping the leaderboard on Echosight!\n\nCurrent Leaderboard:\n#{leaders_list}"
    end

    def new_top_ten_entries_message(result)
      new_entries = result.map do |entry|
        "#{entry[:twitter_handle]} (rank: #{entry[:rank]})"
      end.join("\n")
      "Congratulations to the new entries in the top 10 on Echosight:\n\n#{new_entries}"
    end

    def send_notification(message)
      Notifications::SlackNotifier.call(message: message, channel: :general)
    end
  end
end

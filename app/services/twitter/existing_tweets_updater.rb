# frozen_string_literal: true

module Twitter
  class ExistingTweetsUpdater < Services::Base
    attr_reader :user, :client

    def initialize(user:, client: nil)
      @client = client || SocialData::ClientAdapter.new
      @user = user
    end

    def call
      # add logging later from new_tweets_fetcher.rb
      fetch_and_store_tweets
    end

    private

    def fetch_and_store_tweets
      first_update_tweet_data, subsequent_update_tweet_data = calculate_tweet_ranges(user)
      if first_update_tweet_data[:valid_range]
        p 'fetching first update tweets'
        fetch_and_process_tweets(first_update_tweet_data, user)
      end
      # if subsequent_update_tweet_data[:valid_range]
      #   p 'fetching subsequent update tweets'
      #   fetch_and_process_tweets(subsequent_update_tweet_data, user)
      # end
    end

    def fetch_and_process_tweets(tweet_data, user)
      return unless user.handle && tweet_data[:since].present? && tweet_data[:until].present?

      query = "from:#{user.handle} -filter:replies since_time:#{tweet_data[:since]} until_time:#{tweet_data[:until]}"
      p "query: #{query}"
      tweets = client.search_tweets(query: query)
      today_user_data = nil
      p "tweets #{tweets}"
      if (tweets.count > tweet_data[:tweet_ids].count)
        message = "Tweet count mismatch for user #{user.handle}. Expected: #{tweet_data[:tweet_ids].count}, Actual: #{tweets.count}"
        # ExceptionNotifier.notify_exception(StandardError.new(message, data: { user: user.handle, tweet_data: tweet_data, tweets: tweets }))
      end
      tweets['data'].each do |tweet_data|
        today_user_data ||= tweet_data['user']['data']
        process_tweet_data(tweet_data)
      end
      if today_user_data
        @user_metrics_updated_message = UserMetricsUpdater.new(today_user_data).call
        IdentityUpdater.new(today_user_data).call
      end
    end

    def calculate_tweet_ranges(user)
      tweets_for_first_update_range = calculate_range(user: user, time_threshold: 24.hours.ago)
      p "tweets_for_first_update_range: #{tweets_for_first_update_range}"

      tweets_for_subsequent_updates_range = calculate_range(user: user, time_threshold: 24.hours.ago, since: tweets_for_first_update_range[:since], for_subsequent_updates: true)
      p "tweets_for_subsequent_updates_range: #{tweets_for_subsequent_updates_range}"
      # byebug
      # raise 'end'
      [tweets_for_first_update_range, tweets_for_subsequent_updates_range]
    end

    # "tweets_for_first_update_range: {:tweet_ids=>[2574, 2466, 6375, 6373, 6259, 2469, 6035, 2702, 2543, 6258, 6445, 6458, 2636, 2544, 6219, 2575, 6095, 6084, 6090, 2683, 6015, 5986, 6240, 2579, 2526, 2598, 6331, 2601, 6495, 6086, 6091, 2465, 6473, 2538, 6329, 6462, 2477, 2498, 2475, 2535, 6228, 5994, 6447, 6339, 5991, 6028, 6233, 2534, 2695, 2474, 6249, 6246, 6498, 3331, 6328, 6503, 2688, 6395, 5964, 2450, 6236, 6269, 6423, 2698, 2679, 2699, 6467, 6463, 6441, 6516, 6404, 6365, 6487, 2606, 6512, 6088, 5958, 6408, 2690, 6326, 3318, 6040, 2628, 5968, 5992, 6474, 6036, 6279, 2658, 2444, 6385, 6264, 6366, 6488, 6450, 6390, 3315, 2519, 2641, 6393, 6478, 2615, 6023, 2625, 2499, 2497, 6397, 6355, 3329, 6094, 2433, 6072, 2495, 5989, 2584, 6069, 3332, 2493, 2647, 6056, 6221, 6007, 5996, 3330, 3319, 2492, 6481, 2587, 6254, 5973, 2539, 6477, 6066, 6068, 2553, 2593, 6374, 2576, 6417, 2514, 6425, 2441, 6018, 2667, 2581, 6059, 6332, 6449, 2459, 6523, 2452, 2704, 6362, 6052, 6277, 6078, 6336, 6411, 2485, 6076, 2680, 2685, 6434, 6239, 6081, 2506, 2580, 6253, 2530, 6525, 6407, 6368, 6021, 2507, 2620, 6223, 6272, 6012, 2435, 6518, 5997, 6266, 2476, 2650, 5979, 2634, 3312, 6343, 2454, 6074, 6524, 2558, 6470, 2623, 2491, 6507, 5993, 2463, 6389, 2523, 6245, 5978, 6048, 2439, 6428, 6502, 6433, 2618, 2524, 6400, 6093, 2529, 6509, 5988, 2665, 6003, 6011, 6513, 6427, 2496, 6232, 6482, 2662, 6082, 6363, 2566, 5970, 2462, 2516, 6079, 6465, 2666, 2515, 2436, 5981, 2471, 2502, 6267, 6418, 6280, 3320, 2503, 3334, 2483, 2484, 6367, 6224, 6357, 6494, 3316, 6352, 2596, 6260, 2472, 2696, 6510, 5980, 2671, 6009, 5962, 2437, 6511, 6391, 6505, 6062, 6430, 6002, 6431, 2642, 2631, 6528, 6030, 5998, 6257, 2661, 2684, 2528, 2599, 6013, 6275, 2555, 6346, 6268, 5974, 2605, 6485, 2682, 2594, 6222, 2591, 2513, 6243, 6424, 2447, 6250, 2654, 2691, 5999, 6403, 2536, 2700, 6504, 6020, 6480, 6248, 6041, 6440, 6442, 6044, 2602, 6014, 6475, 2479, 6077, 2545, 6379, 2600, 6420, 2473, 2432, 6416, 2603, 6527, 6045, 2527, 6499, 6406, 5990, 5987, 6242, 6063, 2572, 2532, 5976, 6083, 6446, 6349, 2488, 6402, 5983, 6006, 2578, 2645, 6489, 2511, 2694, 6497, 2458, 3333, 6484, 2649, 2554, 2561, 6405, 2590, 2646, 6255, 2627, 3323, 6358, 6443, 2622, 6338, 2489, 6492, 2517, 6472, 6016, 3326, 2689, 6229, 2664, 2512, 6337, 6421, 6521, 2468, 6251, 6377, 5969, 2652, 6238, 6526, 6017, 2630, 6522, 6426, 6381, 6429, 6051, 5984, 6273, 6455, 6452, 6089, 6235, 2531, 6419, 2659, 2557, 6047, 6476, 2556, 2501, 6019, 2632, 2703, 2509, 6333, 2440, 6461, 6064, 6032, 6262, 2570, 6457, 6327, 6278, 6263, 6335, 2660, 2537, 6384, 6435, 6490, 6225, 2565, 2525, 6371, 6519, 6422, 2571, 2542, 5963, 6080, 3317, 6459, 6065, 6054, 2616, 6392, 6464, 2460, 6413, 2595, 6071, 2438, 2443, 6274, 6437, 6043, 6276, 6479, 2657, 5836, 2655, 6376, 6031, 2568, 6491, 2643, 6340, 6241, 6027, 6348, 6399, 6350, 6438, 2430, 6330, 2687, 6520, 6244, 6270, 6361, 2663, 5995, 2651, 2445, 2449, 2481, 2478, 2635, 2648, 2548, 2518, 6493, 5957, 2621, 6345, 2461, 2604, 2569, 6515, 2693, 5966, 2573, 6448, 2487, 6073, 6380, 6025, 6432, 2500, 6369, 5975, 2585, 6265, 3324, 6386, 6412, 2589, 6008, 6356, 6401, 6341, 6087], :since=>1708566549, :until=>1712787550, :valid_range=>true}"

    def calculate_range(user:, time_threshold:, since: nil, for_subsequent_updates: false)
      base_query = Tweet.joins(:tweet_metrics).where(identity_id: user.identity.id)
      tweets = base_query.where(id: [2574,2466])
      # if for_subsequent_updates
      #   # Ensure that we only consider tweets for subsequent updates where the latest update is older than 24 hours
      #   tweets = base_query.group('tweets.id')
      #                      .having('MAX(tweet_metrics.pulled_at) < ?', 24.hours.ago)
      #                      .having('COUNT(tweet_metrics.id) >= 2')
      # else
      #   # Initial updates only if pulled_at is exactly 24 hours ago, adjust this as per your logic
      #   tweets = base_query.group('tweets.id')
      #                      .having('COUNT(tweet_metrics.id) = 1 AND MAX(tweet_metrics.pulled_at) <= ?', time_threshold)
      # end

      min_tweet = tweets.min_by { |t| t.id }
      max_tweet = tweets.max_by { |t| t.id }

      since_time = min_tweet ? id_to_time(min_tweet.id) - 1 : nil
      until_time = max_tweet ? id_to_time(max_tweet.id) + 1 : nil

      { tweet_ids: tweets.map(&:id), since: since_time, until: until_time, valid_range: min_tweet.present? && max_tweet.present? }
    end

    def id_to_time(tweet_id)
      # Shift right by 22 bits and add the Twitter epoch offset, then convert to seconds
      ((tweet_id >> 22) + 1288834974657) / 1000
    end

    def process_tweet_data(tweet_data)
      Twitter::TweetAndMetricUpserter.call(tweet_data: tweet_data, user: user)
    end
  end
end

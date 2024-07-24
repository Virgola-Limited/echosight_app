class PostSender
  MAX_TWITTER_LENGTH = 280
  MAX_THREAD_LENGTH = 500  # Example length, adjust based on platform requirements

  def initialize(message:, post_type:, channel_type:, mentioned_users: [])
    @message = message
    @post_type = post_type
    @channel_type = channel_type
    @mentioned_users = mentioned_users
    @failure_reasons = []
  end

  def call
    unless valid_message_length?
      @failure_reasons << "Message length exceeds the allowed limit."
    end

    if duplicate_message?
      @failure_reasons << "Duplicate message detected."
    end

    if @failure_reasons.any?
      notify_failure
      return
    end

    SentPost.create!(
      message: @message,
      post_type: @post_type,
      channel_type: @channel_type,
      mentioned_users: @mentioned_users,
      tracking_id: SecureRandom.uuid
    )

    send_to_channel
  end

  private

  def valid_message_length?
    case @channel_type
    when 'twitter'
      @message.length <= MAX_TWITTER_LENGTH
    when 'threads'
      @message.length <= MAX_THREAD_LENGTH
    else
      true  # No length restriction for Slack
    end
  end

  def duplicate_message?
    case @post_type
    when 'one_time'
      SentPost.exists?(message: @message, post_type: 'one_time', channel_type: @channel_type)
    when 'once_a_day'
      SentPost.where('created_at >= ?', 1.day.ago).exists?(message: @message, post_type: 'once_a_day', channel_type: @channel_type)
    when 'once_a_week'
      SentPost.where('created_at >= ?', 1.week.ago).exists?(message: @message, post_type: 'once_a_week', channel_type: @channel_type)
    when 'mention'
      SentPost.where('created_at >= ?', 1.week.ago).where("mentioned_users @> ?", @mentioned_users.to_json).exists?
    else
      false
    end
  end

  def notify_failure
    PostMailer.post_failed_email(@message, @failure_reasons).deliver_now
  end

  def send_to_channel
    case @channel_type
    when 'slack'
      Notifications::SlackNotifier.call(message: @message, channel: :general)
    when 'twitter'
      # Implement Twitter sending logic
    when 'threads'
      # Implement Threads sending logic
    end
  end
end

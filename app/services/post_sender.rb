class PostSender
  MAX_TWITTER_LENGTH = 280
  MAX_THREAD_LENGTH = 500  # Example length, adjust based on platform requirements

  def initialize(message:, post_type:, channel_type:, user: nil, image_url: nil)
    @message = message
    @post_type = post_type
    @channel_type = channel_type
    @user = user
    @image_url = image_url
    @failure_reasons = []
  end

  def call
    unless valid_message_length?
      @failure_reasons << "Message length exceeds the allowed limit."
    end

    if duplicate_message?
      @failure_reasons << "Duplicate message detected."
    end

    unless can_send_post?
      @failure_reasons << "Post cannot be sent more than once a #{@post_type.gsub('_', ' ')}."
    end

    if @failure_reasons.any?
      notify_failure
      return
    end

    SentPost.transaction do
      SentPost.create!(
        message: @message,
        post_type: @post_type,
        channel_type: @channel_type,
        mentioned_users: extract_mentioned_users,
        tracking_id: SecureRandom.uuid,
        sent_at: Time.current
      )

      send_to_channel
    end
  end

  private

  def valid_message_length?
    case @channel_type
    when 'twitter'
      @message.length <= MAX_TWITTER_LENGTH
    when 'threads'
      @message.length <= MAX_THREAD_LENGTH
    else
      @message.length <= 280  # Assuming Slack message length is restricted to 280 characters
    end
  end

  def duplicate_message?
    case @post_type
    when 'one_time'
      SentPost.exists?(message: @message, post_type: 'one_time', channel_type: @channel_type)
    when 'once_a_day'
      SentPost.where('sent_at >= ?', 1.day.ago).exists?(message: @message, post_type: 'once_a_day', channel_type: @channel_type)
    when 'once_a_week'
      SentPost.where('sent_at >= ?', 1.week.ago).exists?(message: @message, post_type: 'once_a_week', channel_type: @channel_type)
    else
      false
    end
  end

  def can_send_post?
    case @post_type
    when 'once_a_day'
      last_sent_at = SentPost.where(message: @message, post_type: 'once_a_day', channel_type: @channel_type).order(sent_at: :desc).limit(1).pluck(:sent_at).first
      last_sent_at.nil? || last_sent_at < 1.day.ago
    when 'once_a_week'
      last_sent_at = SentPost.where(message: @message, post_type: 'once_a_week', channel_type: @channel_type).order(sent_at: :desc).limit(1).pluck(:sent_at).first
      last_sent_at.nil? || last_sent_at < 1.week.ago
    else
      true
    end
  end

  def extract_mentioned_users
    @message.scan(/@\w+/).map { |mention| mention.delete('@') }
  end

  def notify_failure
    PostMailer.post_failed_email(@message, @failure_reasons).deliver_now
  end

  def send_to_channel
    case @channel_type
    when 'slack'
      Notifications::SlackNotifier.call(message: @message, channel: :general)
    when 'twitter'
      response = Twitter::PostService.new(@user, @message, @image_url).call
      unless response
        @failure_reasons << "Failed to post tweet."
        notify_failure
      end
    when 'threads'
      # Implement Threads sending logic
    end
  end
end

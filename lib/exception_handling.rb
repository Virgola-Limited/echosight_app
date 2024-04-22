module ExceptionHandling
  def self.notify_or_raise(exception_or_message, options = {})
    exception = exception_or_message.is_a?(String) ? StandardError.new(exception_or_message) : exception_or_message

    if Rails.env.development?
      raise exception
    else
      ExceptionNotifier.notify_exception(exception, options)
    end
  end
end

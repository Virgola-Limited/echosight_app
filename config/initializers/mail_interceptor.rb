# config/initializers/mail_interceptor.rb

options = { forward_emails_to: 'developer@echosight.io',
            deliver_emails_to: ["@echosight.io"] }

if (ENV['INTERCEPT_EMAILS'])
  interceptor = MailInterceptor::Interceptor.new(options)
  ActionMailer::Base.register_interceptor(interceptor)
end
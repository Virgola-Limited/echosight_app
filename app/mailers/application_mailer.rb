class ApplicationMailer < ActionMailer::Base
  include EmailLogger
  include Rails.application.routes.url_helpers

  default template_path: 'mailers'

  default from: "x@echosight.io"
  layout "mailer"

end

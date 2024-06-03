class ApplicationMailer < ActionMailer::Base
  include EmailLogger

  default template_path: 'mailers'

  default from: "x@echosight.io"
  layout "mailer"

end

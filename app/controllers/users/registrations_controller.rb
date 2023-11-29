class Users::RegistrationsController < Devise::RegistrationsController
  layout 'authenticated'
end

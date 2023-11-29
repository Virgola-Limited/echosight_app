class Users::RegistrationsController < Devise::RegistrationsController
  layout 'authenticated', only: [:edit, :update]
end

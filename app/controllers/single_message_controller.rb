class SingleMessageController < ApplicationController
  def index
    @single_message_partial = if params[:message_type] == 'after_sign_up'
                                'single_message/sign_up'
                              else
                                raise ActionController::RoutingError.new('Not Found')
                              end
  end
end

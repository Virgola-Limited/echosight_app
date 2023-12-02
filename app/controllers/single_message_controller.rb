class SingleMessageController < ApplicationController
  def index
    byebug
    @single_message_partial = if params[:message_type] == 'after_confirmation'
                                'single_message/confirmation'
                              else
                                'single_message/sign_up'
                              end
  end
end

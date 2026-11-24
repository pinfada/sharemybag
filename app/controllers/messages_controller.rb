class MessagesController < ApplicationController
  before_action :signed_in_user

  def create
    @conversation = Conversation.find(params[:conversation_id])
    unless @conversation.participant?(current_user)
      flash[:error] = t('common.unauthorized')
      redirect_to root_url and return
    end

    @message = @conversation.messages.build(message_params)
    @message.sender = current_user

    if @message.save
      other = @conversation.other_participant(current_user)
      Notification.notify(
        other,
        @conversation,
        "new_message",
        t('notifications.new_message', name: current_user.name)
      )
    else
      flash[:error] = @message.errors.full_messages.join(" · ")
    end

    redirect_to @conversation
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end

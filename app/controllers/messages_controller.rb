class MessagesController < ApplicationController
  before_action :signed_in_user

  def create
    @conversation = Conversation.find(params[:conversation_id])
    unless participant?(@conversation)
      redirect_to root_url
      return
    end

    @message = @conversation.messages.build(message_params)
    @message.sender = current_user

    if @message.save
      other = @conversation.other_participant(current_user)
      Notification.notify(other, @conversation, "new_message",
        I18n.t('notifications.new_message', name: current_user.name))

      redirect_to @conversation
    else
      flash[:error] = @message.errors.full_messages.join(", ")
      redirect_to @conversation
    end
  end

  private

  def participant?(conversation)
    conversation.sender_id == current_user.id || conversation.recipient_id == current_user.id
  end

  def message_params
    params.require(:message).permit(:body)
  end
end

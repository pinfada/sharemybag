class ConversationsController < ApplicationController
  before_action :signed_in_user

  def index
    @conversations = Conversation.involving(current_user)
                                 .includes(:sender, :recipient, :messages)
                                 .order(updated_at: :desc)
                                 .paginate(page: params[:page], per_page: 20)
  end

  def show
    @conversation = Conversation.find(params[:id])
    redirect_to root_url unless participant?(@conversation)
    @messages = @conversation.messages.chronological
    @messages.where.not(sender_id: current_user.id).unread.update_all(read: true)
    @message = Message.new
  end

  def create
    recipient = User.find(params[:recipient_id])
    @conversation = Conversation.find_by(sender_id: [current_user.id, recipient.id],
                                         recipient_id: [current_user.id, recipient.id])
    unless @conversation
      @conversation = Conversation.create!(
        sender: current_user,
        recipient: recipient,
        shipping_request_id: params[:shipping_request_id]
      )
    end
    redirect_to @conversation
  end

  private

  def participant?(conversation)
    conversation.sender_id == current_user.id || conversation.recipient_id == current_user.id
  end
end

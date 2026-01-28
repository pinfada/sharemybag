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
    unless participant?(@conversation)
      flash[:error] = I18n.t('common.unauthorized', default: "Unauthorized")
      redirect_to root_url and return
    end
    @messages = @conversation.messages.chronological
    @messages.where.not(sender_id: current_user.id).unread.update_all(read: true)
    @message = Message.new
  end

  def create
    recipient = User.find_by(id: params[:recipient_id])
    unless recipient
      flash[:error] = I18n.t('common.user_not_found', default: "User not found")
      redirect_to root_url and return
    end

    if recipient.id == current_user.id
      flash[:error] = I18n.t('conversations.cannot_message_self', default: "Cannot message yourself")
      redirect_to root_url and return
    end

    @conversation = Conversation.where(
      "(sender_id = :me AND recipient_id = :them) OR (sender_id = :them AND recipient_id = :me)",
      me: current_user.id, them: recipient.id
    ).first

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

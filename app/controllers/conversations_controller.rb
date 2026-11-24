class ConversationsController < ApplicationController
  before_action :signed_in_user

  def index
    @conversations = Conversation.involving(current_user)
                                 .includes(:sender, :recipient, :shipping_request, :messages)
                                 .order(updated_at: :desc)
                                 .paginate(page: params[:page], per_page: 20)
  end

  def show
    @conversation = Conversation.includes(:sender, :recipient, :shipping_request).find(params[:id])
    unless @conversation.participant?(current_user)
      flash[:error] = t('common.unauthorized')
      redirect_to root_url and return
    end

    @messages = @conversation.messages.includes(:sender).chronological
    @messages.where.not(sender_id: current_user.id).unread.update_all(read: true)
    @message = Message.new
    @other_user = @conversation.other_participant(current_user)
  end

  def create
    recipient = User.find_by(id: params[:recipient_id])
    unless recipient
      flash[:error] = t('common.not_found')
      redirect_to root_url and return
    end

    if recipient.id == current_user.id
      flash[:error] = t('conversations.cannot_message_self')
      redirect_to root_url and return
    end

    @conversation = Conversation.between(current_user, recipient)
    unless @conversation
      shipping_request = ShippingRequest.find_by(id: params[:shipping_request_id])
      @conversation = Conversation.create!(
        sender: current_user,
        recipient: recipient,
        shipping_request: shipping_request
      )
    end

    redirect_to @conversation
  end
end

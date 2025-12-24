class Api::V1::MessagesController < ApplicationController
  skip_before_action :authenticate_user! # TODO: MVP後に認証実装
  before_action :set_current_user
  before_action :set_conversation, only: [:create]

  # POST /api/v1/conversations/:conversation_id/messages
  def create
    # 権限チェック
    unless @conversation.participant?(@current_user)
      render json: { error: 'アクセス権限がありません' }, status: :forbidden
      return
    end

    message = @conversation.messages.build(message_params)
    message.sender = @current_user

    if message.save
      # 既読情報を更新（送信者のlast_read_atを更新）
      participant = @conversation.conversation_participants.find_by(user_id: @current_user.id)
      participant&.update(last_read_at: Time.current)

      render json: {
        message: {
          id: message.id,
          sender_id: message.sender_id,
          sender_name: message.sender.name,
          content: message.content,
          created_at: message.created_at
        }
      }, status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: '会話が見つかりません' }, status: :not_found
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def set_current_user
    # TODO: MVP後に認証実装、現在はテストユーザーを使用
    @current_user = User.find_by(email: 'client1@example.com')
  end
end

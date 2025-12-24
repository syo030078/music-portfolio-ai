class Api::V1::ConversationsController < ApplicationController
  before_action :set_conversation, only: [:show]

  # GET /api/v1/conversations
  def index
    # 現在のユーザーが参加している会話を取得（N+1防止）
    conversations = current_user.conversations
      .includes(:participants, :messages, :job, :contract)
      .order(updated_at: :desc)

    render json: {
      conversations: conversations.map do |conversation|
        {
          id: conversation.id,
          job_id: conversation.job_id,
          contract_id: conversation.contract_id,
          created_at: conversation.created_at,
          updated_at: conversation.updated_at,
          participants: conversation.participants.map { |p| { id: p.id, name: p.name } },
          last_message: conversation.messages.last&.then do |msg|
            {
              id: msg.id,
              content: msg.content,
              sender_id: msg.sender_id,
              created_at: msg.created_at
            }
          end,
          unread_count: conversation.unread_count_for(current_user)
        }
      end
    }
  end

  # GET /api/v1/conversations/:id
  def show
    # 権限チェック
    unless @conversation.participant?(current_user)
      render json: { error: 'アクセス権限がありません' }, status: :forbidden
      return
    end

    # メッセージ履歴取得（N+1防止）
    messages = @conversation.messages
      .includes(:sender)
      .order(created_at: :asc)

    render json: {
      conversation: {
        id: @conversation.id,
        job_id: @conversation.job_id,
        contract_id: @conversation.contract_id,
        created_at: @conversation.created_at,
        participants: @conversation.participants.map do |p|
          { id: p.id, name: p.name, bio: p.bio }
        end,
        messages: messages.map do |msg|
          {
            id: msg.id,
            sender_id: msg.sender_id,
            sender_name: msg.sender.name,
            content: msg.content,
            created_at: msg.created_at
          }
        end
      }
    }
  end

  # POST /api/v1/conversations
  def create
    conversation = Conversation.new(conversation_params)

    if conversation.save
      # 参加者を追加
      participant_ids = params[:participant_ids] || []
      participant_ids.each do |user_id|
        conversation.conversation_participants.create!(user_id: user_id)
      end

      # 作成者も参加者に追加
      unless participant_ids.include?(current_user.id)
        conversation.conversation_participants.create!(user_id: current_user.id)
      end

      render json: {
        conversation: {
          id: conversation.id,
          job_id: conversation.job_id,
          contract_id: conversation.contract_id,
          created_at: conversation.created_at
        }
      }, status: :created
    else
      render json: { errors: conversation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: '会話が見つかりません' }, status: :not_found
  end

  def conversation_params
    params.require(:conversation).permit(:job_id, :contract_id)
  end
end

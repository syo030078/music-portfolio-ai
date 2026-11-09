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
          uuid: conversation.id,
          job_uuid: conversation.job&.uuid,
          contract_uuid: conversation.contract&.uuid,
          created_at: conversation.created_at,
          updated_at: conversation.updated_at,
          participants: conversation.participants.map { |p| { uuid: p.uuid, name: p.name } },
          last_message: conversation.messages.last&.then do |msg|
            {
              uuid: msg.uuid,
              content: msg.content,
              sender_uuid: msg.sender.uuid,
              created_at: msg.created_at
            }
          end,
          unread_count: conversation.unread_count_for(current_user)
        }
      end
    }
  end

  # GET /api/v1/conversations/:uuid
  def show
    # 権限チェック
    unless @conversation.participant?(current_user)
      render_forbidden
      return
    end

    # メッセージ履歴取得（N+1防止）
    messages = @conversation.messages
      .includes(:sender)
      .order(created_at: :asc)

    render json: {
      conversation: {
        uuid: @conversation.id,
        job_uuid: @conversation.job&.uuid,
        contract_uuid: @conversation.contract&.uuid,
        created_at: @conversation.created_at,
        participants: @conversation.participants.map do |p|
          { uuid: p.uuid, name: p.name, bio: p.bio }
        end,
        messages: messages.map do |msg|
          {
            uuid: msg.uuid,
            sender_uuid: msg.sender.uuid,
            sender_name: msg.sender.name,
            content: msg.content,
            created_at: msg.created_at
          }
        end
      }
    }
  end

  # POST /api/v1/conversations
  # 参加者は親リソース（案件/契約）の当事者からサーバー側で決める
  def create
    result = ConversationCreationService.call(
      actor: current_user,
      job_uuid: conversation_params[:job_uuid],
      contract_uuid: conversation_params[:contract_uuid]
    )

    unless result.success?
      render_error(result.error, result.status)
      return
    end

    conversation = result.conversation
    render json: {
      conversation: {
        uuid: conversation.id,
        job_uuid: conversation.job&.uuid,
        contract_uuid: conversation.contract&.uuid,
        created_at: conversation.created_at
      }
    }, status: :created
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('会話が見つかりません', :not_found)
  end

  def conversation_params
    params.require(:conversation).permit(:job_uuid, :contract_uuid)
  end
end

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
      render json: { error: 'アクセス権限がありません' }, status: :forbidden
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
  def create
    conversation = Conversation.new(build_conversation_params)

    if conversation.save
      # 参加者を追加（UUIDまたはIDで受け付け）
      participant_uuids = params[:participant_uuids] || []
      participant_ids = params[:participant_ids] || []

      participant_uuids.each do |uuid|
        user = User.find_by(uuid: uuid)
        conversation.conversation_participants.create!(user: user) if user
      end

      participant_ids.each do |user_id|
        conversation.conversation_participants.create!(user_id: user_id)
      end

      # 作成者も参加者に追加
      unless conversation.participants.include?(current_user)
        conversation.conversation_participants.create!(user_id: current_user.id)
      end

      render json: {
        conversation: {
          uuid: conversation.id,
          job_uuid: conversation.job&.uuid,
          contract_uuid: conversation.contract&.uuid,
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

  def build_conversation_params
    conv_params = params.require(:conversation).permit(:job_id, :contract_id, :job_uuid, :contract_uuid)

    # UUIDからIDへ変換
    if conv_params[:job_uuid].present?
      job = Job.find_by(uuid: conv_params[:job_uuid])
      conv_params[:job_id] = job&.id
    end

    if conv_params[:contract_uuid].present?
      contract = Contract.find_by(uuid: conv_params[:contract_uuid])
      conv_params[:contract_id] = contract&.id
    end

    conv_params.except(:job_uuid, :contract_uuid)
  end

end

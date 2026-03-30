class Api::V1::MessagesController < ApplicationController
  before_action :set_conversation, only: [:index, :create]

  # GET /api/v1/conversations/:conversation_id/messages
  # params: since (ISO8601) - 指定時刻以降のメッセージのみ返す
  #         limit (integer) - 取得件数（デフォルト50、最大100）
  #         before (UUID)   - 指定UUIDより前のメッセージを返す（過去遡り用）
  def index
    unless @conversation.participant?(current_user)
      render json: { error: 'アクセス権限がありません' }, status: :forbidden
      return
    end

    messages = @conversation.messages.includes(:sender).order(created_at: :asc)

    if params[:since].present?
      since_time = begin
        Time.zone.parse(params[:since])
      rescue ArgumentError
        nil
      end
      if since_time.nil?
        render json: { error: 'since パラメータの形式が不正です (ISO8601)' }, status: :bad_request
        return
      end
      messages = messages.where('messages.created_at > ?', since_time)
    end

    if params[:before].present?
      before_message = @conversation.messages.find_by(uuid: params[:before])
      messages = messages.where('messages.created_at < ?', before_message.created_at) if before_message
    end

    limit = [[params.fetch(:limit, 50).to_i, 1].max, 100].min
    fetched = messages.limit(limit + 1).to_a
    has_more = fetched.size > limit
    messages_to_render = fetched.first(limit)

    # 新着がある場合のみ既読情報を更新（不要なDB書き込みを防ぐ）
    if messages_to_render.any?
      participant = @conversation.conversation_participants.find_by(user_id: current_user.id)
      if participant && (participant.last_read_at.nil? || messages_to_render.last.created_at > participant.last_read_at)
        participant.mark_as_read!
      end
    end

    render json: {
      messages: messages_to_render.map { |msg| message_json(msg) },
      meta: {
        has_more: has_more,
        oldest_uuid: messages_to_render.first&.uuid
      }
    }
  end

  # POST /api/v1/conversations/:conversation_uuid/messages
  def create
    # 権限チェック
    unless @conversation.participant?(current_user)
      render json: { error: 'アクセス権限がありません' }, status: :forbidden
      return
    end

    message = @conversation.messages.build(message_params)
    message.sender = current_user

    if message.save
      # 既読情報を更新（送信者のlast_read_atを更新）
      participant = @conversation.conversation_participants.find_by(user_id: current_user.id)
      participant&.mark_as_read!

      render json: { message: message_json(message) }, status: :created
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

  def message_json(msg)
    {
      uuid: msg.uuid,
      sender_uuid: msg.sender.uuid,
      sender_name: msg.sender.name,
      content: msg.content,
      created_at: msg.created_at
    }
  end

end

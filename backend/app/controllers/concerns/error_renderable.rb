# API共通のエラーレスポンス
#   単一メッセージ: { error: "..." }
#   バリデーション: { errors: ["...", ...] }
module ErrorRenderable
  extend ActiveSupport::Concern

  private

  def render_error(message, status)
    render json: { error: message }, status: status
  end

  def render_forbidden(message = 'アクセス権限がありません')
    render_error(message, :forbidden)
  end

  def render_validation_errors(record)
    render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
  end
end

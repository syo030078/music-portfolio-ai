# 案件または契約に紐づく会話を作る。
# 参加者はクライアントから受け取らず、親リソースの当事者からサーバー側で決める
#   案件: 操作者 + 案件のクライアント（公開中の案件のみ）
#   契約: 契約のクライアント + ミュージシャン（当事者のみ作成可）
class ConversationCreationService
  Result = Struct.new(:success?, :conversation, :error, :status, keyword_init: true)

  def self.call(actor:, job_uuid: nil, contract_uuid: nil)
    new(actor, job_uuid, contract_uuid).call
  end

  def initialize(actor, job_uuid, contract_uuid)
    @actor = actor
    @job_uuid = job_uuid.presence
    @contract_uuid = contract_uuid.presence
  end

  def call
    unless job_uuid.nil? ^ contract_uuid.nil?
      return failure('job_uuid と contract_uuid のどちらか一方を指定してください', :unprocessable_entity)
    end

    job_uuid ? create_for_job : create_for_contract
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.join(', '), :unprocessable_entity)
  end

  private

  attr_reader :actor, :job_uuid, :contract_uuid

  def create_for_job
    job = Job.published.find_by(uuid: job_uuid)
    return failure('案件が見つかりません', :not_found) if job.nil?
    return failure('自分の案件には問い合わせできません', :unprocessable_entity) if job.client_id == actor.id

    create_conversation({ job: job }, [actor, job.client])
  end

  def create_for_contract
    contract = Contract.find_by(uuid: contract_uuid)
    return failure('契約が見つかりません', :not_found) if contract.nil?
    return failure('アクセス権限がありません', :forbidden) unless [contract.client_id, contract.musician_id].include?(actor.id)

    create_conversation({ contract: contract }, [contract.client, contract.musician])
  end

  def create_conversation(parent, participants)
    conversation = ActiveRecord::Base.transaction do
      Conversation.create!(parent).tap do |created|
        participants.uniq.each { |user| ConversationParticipant.create!(conversation: created, user: user) }
      end
    end

    success(conversation)
  end

  def success(conversation)
    Result.new(success?: true, conversation: conversation, status: :created)
  end

  def failure(message, status)
    Result.new(success?: false, error: message, status: status)
  end
end

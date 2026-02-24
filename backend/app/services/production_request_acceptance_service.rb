class ProductionRequestAcceptanceService
  Result = Struct.new(:success?, :production_request, :contract, :conversation, :error, :status, keyword_init: true)

  def self.call(production_request:, actor:)
    new(production_request, actor).call
  end

  def initialize(production_request, actor)
    @production_request = production_request
    @actor = actor
  end

  def call
    return failure('権限がありません', :forbidden) unless actor_can_accept?
    return failure('リクエストは既に承諾されています', :unprocessable_entity) if production_request.accepted?
    return failure('リクエストは既に拒否されています', :unprocessable_entity) if production_request.rejected?
    return failure('リクエストは取り下げられています', :unprocessable_entity) if production_request.withdrawn?
    return failure('契約が既に存在します', :unprocessable_entity) if production_request.contract.present?

    created_contract = nil
    created_conversation = nil

    ActiveRecord::Base.transaction do
      production_request.update!(status: 'accepted')

      created_contract = Contract.create!(
        production_request: production_request,
        client: production_request.client,
        musician: production_request.musician,
        escrow_total_jpy: production_request.budget_jpy,
        status: 'active'
      )

      created_conversation = Conversation.create!(contract: created_contract)
      ConversationParticipant.create!(conversation: created_conversation, user: production_request.client)
      ConversationParticipant.create!(conversation: created_conversation, user: production_request.musician)
    end

    success(production_request: production_request, contract: created_contract, conversation: created_conversation)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.join(', '), :unprocessable_entity)
  end

  private

  attr_reader :production_request, :actor

  def actor_can_accept?
    actor.present? && production_request.musician_id == actor.id
  end

  def success(production_request:, contract:, conversation:)
    Result.new(success?: true, production_request: production_request, contract: contract, conversation: conversation, status: :ok)
  end

  def failure(message, status)
    Result.new(success?: false, error: message, status: status)
  end
end

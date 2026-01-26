class ProposalAcceptanceService
  Result = Struct.new(:success?, :proposal, :contract, :conversation, :error, :status, keyword_init: true)

  def self.call(proposal:, actor:)
    new(proposal, actor).call
  end

  def initialize(proposal, actor)
    @proposal = proposal
    @actor = actor
  end

  def call
    return failure('権限がありません', :forbidden) unless actor_can_accept?
    return failure('提案は既に承諾されています', :unprocessable_entity) if proposal.accepted?
    return failure('提案は既に拒否されています', :unprocessable_entity) if proposal.rejected?
    return failure('案件は既に契約済みです', :unprocessable_entity) if job_contracted?
    return failure('案件が公開されていません', :unprocessable_entity) unless proposal.job.published?
    return failure('契約が既に存在します', :unprocessable_entity) if proposal.contract.present?

    created_contract = nil
    created_conversation = nil

    ActiveRecord::Base.transaction do
      proposal.update!(status: 'accepted')
      proposal.job.update!(status: 'contracted')

      created_contract = Contract.create!(
        proposal: proposal,
        client: proposal.job.client,
        musician: proposal.musician,
        escrow_total_jpy: proposal.quote_total_jpy,
        status: 'active'
      )

      created_conversation = Conversation.create!(contract: created_contract)
      ConversationParticipant.create!(conversation: created_conversation, user: proposal.job.client)
      ConversationParticipant.create!(conversation: created_conversation, user: proposal.musician)
    end

    success(proposal: proposal, contract: created_contract, conversation: created_conversation)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.join(', '), :unprocessable_entity)
  end

  private

  attr_reader :proposal, :actor

  def actor_can_accept?
    actor.present? && proposal.job.client_id == actor.id
  end

  def job_contracted?
    proposal.job.contracted? || Contract.joins(:proposal).where(proposals: { job_id: proposal.job_id }).exists?
  end

  def success(proposal:, contract:, conversation:)
    Result.new(success?: true, proposal: proposal, contract: contract, conversation: conversation, status: :ok)
  end

  def failure(message, status)
    Result.new(success?: false, error: message, status: status)
  end
end

class Api::V1::ProposalsController < ApplicationController
  before_action :set_job, only: [:index, :create]
  before_action :set_proposal, only: [:accept, :reject]

  # POST /api/v1/jobs/:uuid/proposals
  def create
    unless current_user.is_musician?
      render_forbidden('ミュージシャンのみ応募できます')
      return
    end

    proposal = @job.proposals.new(proposal_params.merge(musician: current_user))

    if proposal.save
      proposal.reload
      render json: { proposal: proposal_payload(proposal) }, status: :created
    else
      render_validation_errors(proposal)
    end
  end

  # GET /api/v1/jobs/:uuid/proposals
  def index
    unless @job.client_id == current_user.id
      render_forbidden
      return
    end

    proposals = @job.proposals.includes(:musician).order(created_at: :desc)
    render json: { proposals: proposals.map { |proposal| proposal_payload(proposal) } }
  end

  # POST /api/v1/proposals/:uuid/accept
  def accept
    result = ProposalAcceptanceService.call(proposal: @proposal, actor: current_user)

    if result.success?
      result.contract.reload
      result.proposal.reload
      render json: {
        proposal: proposal_payload(result.proposal),
        contract_uuid: result.contract.uuid,
        conversation_uuid: result.conversation.id
      }, status: :ok
    else
      render_error(result.error, result.status)
    end
  end

  # POST /api/v1/proposals/:uuid/reject
  def reject
    unless @proposal.job.client_id == current_user.id
      render_forbidden
      return
    end

    if @proposal.accepted?
      render_error('承諾済みの提案は拒否できません', :unprocessable_entity)
      return
    end

    if @proposal.rejected?
      render_error('既に拒否されています', :unprocessable_entity)
      return
    end

    if @proposal.update(status: 'rejected')
      render json: { proposal: proposal_payload(@proposal) }, status: :ok
    else
      render_validation_errors(@proposal)
    end
  end

  private

  def set_job
    job_uuid = params[:job_uuid] || params[:job_id]
    @job = Job.find_by!(uuid: job_uuid)
  rescue ActiveRecord::RecordNotFound
    render_error('案件が見つかりません', :not_found)
  end

  def set_proposal
    @proposal = Proposal.find_by!(uuid: params[:uuid] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('提案が見つかりません', :not_found)
  end

  def proposal_params
    params.require(:proposal).permit(:quote_total_jpy, :delivery_days, :cover_message)
  end

  def proposal_payload(proposal)
    {
      uuid: proposal.uuid,
      job_uuid: proposal.job.uuid,
      musician: {
        uuid: proposal.musician.uuid,
        name: proposal.musician.name
      },
      quote_total_jpy: proposal.quote_total_jpy,
      delivery_days: proposal.delivery_days,
      cover_message: proposal.cover_message,
      status: proposal.status,
      created_at: proposal.created_at
    }
  end
end

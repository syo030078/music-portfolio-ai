class Api::V1::ProductionRequestsController < ApplicationController
  before_action :set_production_request, only: [:show, :accept, :reject, :withdraw]

  # GET /api/v1/production_requests
  def index
    scope = current_user.is_client? ? :for_client : :for_musician
    requests = ProductionRequest
                 .send(scope, current_user.id)
                 .includes(:client, :musician)
                 .order(created_at: :desc)

    render json: { production_requests: requests.map { |r| production_request_payload(r) } }
  end

  # GET /api/v1/production_requests/:uuid
  def show
    unless participant?
      render_forbidden
      return
    end

    render json: { production_request: production_request_payload(@production_request) }
  end

  # POST /api/v1/production_requests
  def create
    unless current_user.is_client?
      render_forbidden('クライアントのみ制作リクエストを送れます')
      return
    end

    musician = User.find_by(uuid: params.dig(:production_request, :musician_uuid))
    if musician.nil?
      render_error('ミュージシャンが見つかりません', :not_found)
      return
    end

    unless musician.is_musician?
      render_error('指定されたユーザーはミュージシャンではありません', :unprocessable_entity)
      return
    end

    request = ProductionRequest.new(
      production_request_params.merge(client: current_user, musician: musician)
    )

    if request.save
      request.reload
      render json: { production_request: production_request_payload(request) }, status: :created
    else
      render_validation_errors(request)
    end
  end

  # POST /api/v1/production_requests/:uuid/accept
  def accept
    result = ProductionRequestAcceptanceService.call(
      production_request: @production_request,
      actor: current_user
    )

    if result.success?
      result.contract.reload
      result.production_request.reload
      render json: {
        production_request: production_request_payload(result.production_request),
        contract_uuid: result.contract.uuid,
        conversation_uuid: result.conversation.id
      }, status: :ok
    else
      render_error(result.error, result.status)
    end
  end

  # POST /api/v1/production_requests/:uuid/reject
  def reject
    unless @production_request.musician_id == current_user.id
      render_forbidden
      return
    end

    if @production_request.accepted?
      render_error('承諾済みのリクエストは拒否できません', :unprocessable_entity)
      return
    end

    if @production_request.rejected?
      render_error('既に拒否されています', :unprocessable_entity)
      return
    end

    if @production_request.withdrawn?
      render_error('取り下げられたリクエストは拒否できません', :unprocessable_entity)
      return
    end

    if @production_request.update(status: 'rejected')
      render json: { production_request: production_request_payload(@production_request) }, status: :ok
    else
      render_validation_errors(@production_request)
    end
  end

  # POST /api/v1/production_requests/:uuid/withdraw
  def withdraw
    unless @production_request.client_id == current_user.id
      render_forbidden
      return
    end

    unless @production_request.pending?
      render_error('保留中のリクエストのみ取り下げ可能です', :unprocessable_entity)
      return
    end

    if @production_request.update(status: 'withdrawn')
      render json: { production_request: production_request_payload(@production_request) }, status: :ok
    else
      render_validation_errors(@production_request)
    end
  end

  private

  def set_production_request
    @production_request = ProductionRequest.find_by!(uuid: params[:uuid] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('制作リクエストが見つかりません', :not_found)
  end

  def production_request_params
    params.require(:production_request).permit(:title, :description, :budget_jpy, :delivery_days)
  end

  def participant?
    current_user.id == @production_request.client_id ||
      current_user.id == @production_request.musician_id
  end

  def production_request_payload(request)
    {
      uuid: request.uuid,
      title: request.title,
      description: request.description,
      budget_jpy: request.budget_jpy,
      delivery_days: request.delivery_days,
      status: request.status,
      client: {
        uuid: request.client.uuid,
        name: request.client.name
      },
      musician: {
        uuid: request.musician.uuid,
        name: request.musician.name
      },
      created_at: request.created_at
    }
  end
end

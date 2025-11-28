class Api::V1::JobsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_job, only: [:show, :update, :destroy, :publish]
  before_action :authorize_owner!, only: [:update, :destroy, :publish]

  # GET /api/v1/jobs
  def index
    # ページネーション設定
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 10
    per_page = [per_page, 50].min

    # 公開中の案件のみ取得
    jobs = Job.published.includes(:client)

    # フィルタリング: budget_min
    if params[:budget_min].present?
      jobs = jobs.where('budget_min_jpy >= ? OR budget_jpy >= ?', params[:budget_min].to_i, params[:budget_min].to_i)
    end

    # フィルタリング: budget_max
    if params[:budget_max].present?
      jobs = jobs.where('budget_max_jpy <= ? OR budget_jpy <= ?', params[:budget_max].to_i, params[:budget_max].to_i)
    end

    # フィルタリング: is_remote
    if params[:is_remote].present?
      jobs = jobs.where(is_remote: params[:is_remote] == 'true')
    end

    # ソート（新しい順）
    jobs = jobs.order(published_at: :desc)

    # ページネーション適用
    total_count = jobs.count
    total_pages = (total_count.to_f / per_page).ceil
    jobs = jobs.offset((page - 1) * per_page).limit(per_page)

    # レスポンス生成
    render json: {
      jobs: jobs.map { |job| job_json(job) },
      pagination: {
        current_page: page,
        total_pages: total_pages,
        total_count: total_count,
        per_page: per_page
      }
    }
  end

  # GET /api/v1/jobs/:uuid
  def show
    render json: {
      job: job_detail_json(@job)
    }
  end

  # POST /api/v1/jobs
  def create
    job = Job.new(job_params)
    job.client = current_user

    if job.save
      render json: {
        message: "案件を作成しました",
        job: job_detail_json(job)
      }, status: :created
    else
      render json: {
        error: job.errors.full_messages.join(", ")
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/jobs/:uuid
  def update
    if @job.update(job_params)
      render json: {
        message: "案件を更新しました",
        job: job_detail_json(@job)
      }
    else
      render json: {
        error: @job.errors.full_messages.join(", ")
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/jobs/:uuid
  def destroy
    @job.destroy
    render json: {
      message: "案件を削除しました"
    }
  end

  # POST /api/v1/jobs/:uuid/publish
  def publish
    if @job.update(status: 'published', published_at: Time.current)
      render json: {
        message: "案件を公開しました",
        job: job_detail_json(@job)
      }
    else
      render json: {
        error: @job.errors.full_messages.join(", ")
      }, status: :unprocessable_entity
    end
  end

  private

  def set_job
    @job = Job.find_by_uuid(params[:uuid])
    if @job.nil?
      render json: { error: "案件が見つかりません" }, status: :not_found
    end
  end

  def authorize_owner!
    unless @job.client_id == current_user.id
      render json: { error: "権限がありません" }, status: :forbidden
    end
  end

  def job_params
    params.require(:job).permit(
      :title,
      :description,
      :budget_jpy,
      :budget_min_jpy,
      :budget_max_jpy,
      :delivery_due_on,
      :is_remote,
      :location_note
    )
  end

  def job_json(job)
    {
      uuid: job.uuid,
      title: job.title,
      description: job.description,
      budget_jpy: job.budget_jpy,
      budget_min_jpy: job.budget_min_jpy,
      budget_max_jpy: job.budget_max_jpy,
      is_remote: job.is_remote,
      published_at: job.published_at,
      client: {
        uuid: job.client.uuid,
        name: job.client.name
      }
    }
  end

  def job_detail_json(job)
    {
      uuid: job.uuid,
      title: job.title,
      description: job.description,
      budget_jpy: job.budget_jpy,
      budget_min_jpy: job.budget_min_jpy,
      budget_max_jpy: job.budget_max_jpy,
      delivery_due_on: job.delivery_due_on,
      is_remote: job.is_remote,
      location_note: job.location_note,
      status: job.status,
      published_at: job.published_at,
      created_at: job.created_at,
      client: {
        uuid: job.client.uuid,
        name: job.client.name,
        bio: job.client.bio
      }
    }
  end
end

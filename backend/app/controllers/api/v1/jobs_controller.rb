class Api::V1::JobsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  # GET /api/v1/jobs
  def index
    # ページネーション設定
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 10
    per_page = [per_page, 50].min # 最大50件

    # 公開中の案件のみ表示（認証なしの場合）
    jobs = if current_user
      # 認証済みユーザーは自分の全案件も表示
      Job.includes(:client).where("status = 'published' OR client_id = ?", current_user.id)
    else
      Job.published.includes(:client)
    end

    # ソート（新しい順）
    jobs = jobs.order(created_at: :desc)

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
    job = Job.includes(:client).find_by(uuid: params[:id])

    if job.nil?
      render json: { error: "案件が見つかりません" }, status: :not_found
      return
    end

    # draft の場合は所有者のみ閲覧可能
    if job.draft? && (!current_user || job.client_id != current_user.id)
      render json: { error: "この案件にアクセスする権限がありません" }, status: :forbidden
      return
    end

    render json: { job: job_json(job, detailed: true) }
  end

  # POST /api/v1/jobs
  def create
    job = current_user.jobs.build(job_params)

    if job.save
      render json: {
        message: "案件を作成しました",
        job: job_json(job)
      }, status: :created
    else
      render json: {
        error: job.errors.full_messages.join(", ")
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/jobs/:uuid
  def update
    job = Job.find_by(uuid: params[:id])

    if job.nil?
      render json: { error: "案件が見つかりません" }, status: :not_found
      return
    end

    # 所有者チェック
    unless job.client_id == current_user.id
      render json: { error: "この案件を更新する権限がありません" }, status: :forbidden
      return
    end

    if job.update(job_params)
      render json: {
        message: "案件を更新しました",
        job: job_json(job)
      }
    else
      render json: {
        error: job.errors.full_messages.join(", ")
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/jobs/:uuid
  def destroy
    job = Job.find_by(uuid: params[:id])

    if job.nil?
      render json: { error: "案件が見つかりません" }, status: :not_found
      return
    end

    # 所有者チェック
    unless job.client_id == current_user.id
      render json: { error: "この案件を削除する権限がありません" }, status: :forbidden
      return
    end

    job.destroy
    render json: { message: "案件を削除しました" }
  end

  # POST /api/v1/jobs/:uuid/publish
  def publish
    job = Job.find_by(uuid: params[:id])

    if job.nil?
      render json: { error: "案件が見つかりません" }, status: :not_found
      return
    end

    # 所有者チェック
    unless job.client_id == current_user.id
      render json: { error: "この案件を公開する権限がありません" }, status: :forbidden
      return
    end

    # draft 以外は公開できない
    unless job.draft?
      render json: { error: "draft 状態の案件のみ公開できます" }, status: :unprocessable_entity
      return
    end

    job.status = 'published'
    job.published_at = Time.current

    if job.save
      render json: {
        message: "案件を公開しました",
        job: job_json(job)
      }
    else
      render json: {
        error: job.errors.full_messages.join(", ")
      }, status: :unprocessable_entity
    end
  end

  private

  def job_params
    params.require(:job).permit(
      :title,
      :description,
      :budget_jpy,
      :budget_min_jpy,
      :budget_max_jpy,
      :delivery_due_on,
      :is_remote,
      :location_note,
      :track_id
    )
  end

  def job_json(job, detailed: false)
    base = {
      uuid: job.uuid,
      title: job.title,
      description: job.description,
      status: job.status,
      budget_jpy: job.budget_jpy,
      budget_min_jpy: job.budget_min_jpy,
      budget_max_jpy: job.budget_max_jpy,
      is_remote: job.is_remote,
      published_at: job.published_at,
      created_at: job.created_at
    }

    if detailed
      base.merge!({
        delivery_due_on: job.delivery_due_on,
        location_note: job.location_note,
        track_id: job.track_id,
        updated_at: job.updated_at
      })
    end

    base
  end
end

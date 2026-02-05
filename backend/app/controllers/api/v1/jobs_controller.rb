class Api::V1::JobsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    # 公開済み案件のみ取得（N+1問題防止）
    jobs = Job.published.includes(:client).order(published_at: :desc)

    render json: {
      jobs: jobs.map do |job|
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
    }
  end

  def show
    job = Job.published.includes(:client).find_by(uuid: params[:uuid])

    if job.nil?
      render json: { error: "案件が見つかりません" }, status: :not_found
      return
    end

    render json: {
      job: {
        uuid: job.uuid,
        title: job.title,
        description: job.description,
        budget_jpy: job.budget_jpy,
        budget_min_jpy: job.budget_min_jpy,
        budget_max_jpy: job.budget_max_jpy,
        is_remote: job.is_remote,
        delivery_due_on: job.delivery_due_on,
        published_at: job.published_at,
        created_at: job.created_at,
        client: {
          uuid: job.client.uuid,
          name: job.client.name,
          bio: job.client.bio
        }
      }
    }
  end

  # GET /api/v1/jobs/my_jobs
  def my_jobs
    jobs = current_user.jobs.includes(:proposals).order(created_at: :desc)

    render json: {
      jobs: jobs.map do |job|
        {
          uuid: job.uuid,
          title: job.title,
          description: job.description,
          budget_jpy: job.budget_jpy,
          budget_min_jpy: job.budget_min_jpy,
          budget_max_jpy: job.budget_max_jpy,
          is_remote: job.is_remote,
          delivery_due_on: job.delivery_due_on,
          status: job.status,
          published_at: job.published_at,
          created_at: job.created_at,
          proposals_count: job.proposals.count
        }
      end
    }
  end

  def create
    job = current_user.jobs.new(job_params)
    job.status = 'draft'

    if job.save
      render json: { job: job_response(job) }, status: :created
    else
      render json: { errors: job.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    job = current_user.jobs.find_by(uuid: params[:uuid])

    if job.nil?
      render json: { error: '案件が見つかりません' }, status: :not_found
      return
    end

    if job.update(job_params)
      render json: { job: job_response(job) }, status: :ok
    else
      render json: { errors: job.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def publish
    job = current_user.jobs.find_by(uuid: params[:uuid])

    if job.nil?
      render json: { error: '案件が見つかりません' }, status: :not_found
      return
    end

    if job.status == 'published'
      render json: { error: '案件は既に公開されています (already published)' }, status: :unprocessable_entity
      return
    end

    job.update!(status: 'published', published_at: Time.current)
    render json: { job: job_response(job) }, status: :ok
  end

  private

  def job_params
    params.require(:job).permit(:title, :description, :budget_min_jpy, :budget_max_jpy, :budget_jpy, :delivery_due_on, :is_remote)
  end

  def job_response(job)
    {
      uuid: job.uuid,
      title: job.title,
      description: job.description,
      budget_jpy: job.budget_jpy,
      budget_min_jpy: job.budget_min_jpy,
      budget_max_jpy: job.budget_max_jpy,
      is_remote: job.is_remote,
      delivery_due_on: job.delivery_due_on,
      status: job.status,
      published_at: job.published_at,
      created_at: job.created_at
    }
  end
end

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
            id: job.client.id,
            name: job.client.name
          }
        }
      end
    }
  end

  def show
    job = Job.published.includes(:client).find_by(uuid: params[:id])

    if job.nil?
      render json: { error: "案件が見つかりません" }, status: :not_found
      return
    end

    render json: {
      job: {
        id: job.id,
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
          id: job.client.id,
          name: job.client.name,
          bio: job.client.bio
        }
      }
    }
  end
end

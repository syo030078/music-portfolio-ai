require 'rails_helper'

RSpec.describe Api::V1::JobsController, type: :controller do
  let(:client_user) { User.create!(email: 'client@example.com', password: 'password123', name: 'Client User') }
  let(:musician_user) { User.create!(email: 'musician@example.com', password: 'password123', name: 'Musician User') }

  describe "GET #index" do
    before do
      # 公開案件
      Job.create!(
        client: client_user,
        title: 'Public Job 1',
        description: 'A public job description',
        status: 'published',
        published_at: Time.current,
        budget_min_jpy: 10000,
        budget_max_jpy: 50000
      )
      Job.create!(
        client: client_user,
        title: 'Public Job 2',
        description: 'Another public job',
        status: 'published',
        published_at: Time.current,
        budget_min_jpy: 20000,
        budget_max_jpy: 100000
      )
      # Draft案件（公開されていない）
      Job.create!(
        client: client_user,
        title: 'Draft Job',
        description: 'A draft job',
        status: 'draft',
        budget_min_jpy: 5000,
        budget_max_jpy: 10000
      )
    end

    it "returns published jobs without authentication" do
      get :index
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["jobs"]).to be_an(Array)
      expect(json["jobs"].length).to eq(2) # 公開案件のみ
      expect(json["pagination"]).to be_present
    end

    it "includes pagination information" do
      get :index
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["pagination"]["current_page"]).to eq(1)
      expect(json["pagination"]["total_count"]).to eq(2)
      expect(json["pagination"]["per_page"]).to eq(10)
    end

    it "returns jobs ordered by created_at desc" do
      get :index
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      titles = json["jobs"].map { |j| j["title"] }
      expect(titles).to eq(['Public Job 2', 'Public Job 1']) # 新しい順
    end

    it "supports pagination with page and per_page parameters" do
      get :index, params: { page: 1, per_page: 1 }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["jobs"].length).to eq(1)
      expect(json["pagination"]["total_pages"]).to eq(2)
    end

    it "shows own draft jobs when authenticated" do
      sign_in client_user
      get :index
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["jobs"].length).to eq(3) # 公開2件 + 自分のdraft1件
    end
  end

  describe "GET #show" do
    let(:published_job) do
      Job.create!(
        client: client_user,
        title: 'Test Job',
        description: 'Test description',
        status: 'published',
        published_at: Time.current,
        budget_min_jpy: 10000,
        budget_max_jpy: 50000
      )
    end

    let(:draft_job) do
      Job.create!(
        client: client_user,
        title: 'Draft Job',
        description: 'Draft description',
        status: 'draft',
        budget_min_jpy: 5000,
        budget_max_jpy: 10000
      )
    end

    it "returns published job detail without authentication" do
      get :show, params: { id: published_job.uuid }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["job"]["uuid"]).to eq(published_job.uuid)
      expect(json["job"]["title"]).to eq('Test Job')
    end

    it "returns 403 for draft job without authentication" do
      get :show, params: { id: draft_job.uuid }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns draft job detail when authenticated as owner" do
      sign_in client_user
      get :show, params: { id: draft_job.uuid }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["job"]["uuid"]).to eq(draft_job.uuid)
    end

    it "returns 403 for draft job when authenticated as non-owner" do
      sign_in musician_user
      get :show, params: { id: draft_job.uuid }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for non-existent job" do
      get :show, params: { id: 'non-existent-uuid' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create" do
    before do
      sign_in client_user
    end

    it "creates a job with valid parameters" do
      expect {
        post :create, params: {
          job: {
            title: 'New Job',
            description: 'New job description',
            budget_min_jpy: 10000,
            budget_max_jpy: 50000
          }
        }
      }.to change(Job, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("案件を作成しました")
      expect(json["job"]["title"]).to eq('New Job')
    end

    it "returns error with invalid parameters" do
      post :create, params: {
        job: {
          title: '',
          description: ''
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to be_present
    end

    it "requires authentication" do
      sign_out client_user
      post :create, params: {
        job: {
          title: 'New Job',
          description: 'Description'
        }
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH #update" do
    let(:job) do
      Job.create!(
        client: client_user,
        title: 'Original Title',
        description: 'Original description',
        status: 'draft',
        budget_min_jpy: 10000,
        budget_max_jpy: 50000
      )
    end

    before do
      sign_in client_user
    end

    it "updates job with valid parameters" do
      patch :update, params: {
        id: job.uuid,
        job: { title: 'Updated Title' }
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["job"]["title"]).to eq('Updated Title')

      job.reload
      expect(job.title).to eq('Updated Title')
    end

    it "returns error with invalid parameters" do
      patch :update, params: {
        id: job.uuid,
        job: { title: '' }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 403 when updating as non-owner" do
      sign_in musician_user
      patch :update, params: {
        id: job.uuid,
        job: { title: 'Hacked Title' }
      }

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for non-existent job" do
      patch :update, params: {
        id: 'non-existent-uuid',
        job: { title: 'Updated' }
      }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE #destroy" do
    let(:job) do
      Job.create!(
        client: client_user,
        title: 'Job to Delete',
        description: 'Will be deleted',
        status: 'draft',
        budget_min_jpy: 10000,
        budget_max_jpy: 50000
      )
    end

    before do
      sign_in client_user
    end

    it "deletes job as owner" do
      expect {
        delete :destroy, params: { id: job.uuid }
      }.to change(Job, :count).by(-1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("案件を削除しました")
    end

    it "returns 403 when deleting as non-owner" do
      sign_in musician_user
      expect {
        delete :destroy, params: { id: job.uuid }
      }.to_not change(Job, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for non-existent job" do
      delete :destroy, params: { id: 'non-existent-uuid' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #publish" do
    let(:draft_job) do
      Job.create!(
        client: client_user,
        title: 'Draft Job',
        description: 'To be published',
        status: 'draft',
        budget_min_jpy: 10000,
        budget_max_jpy: 50000
      )
    end

    let(:published_job) do
      Job.create!(
        client: client_user,
        title: 'Already Published',
        description: 'Already published',
        status: 'published',
        published_at: Time.current,
        budget_min_jpy: 10000,
        budget_max_jpy: 50000
      )
    end

    before do
      sign_in client_user
    end

    it "publishes draft job" do
      post :publish, params: { id: draft_job.uuid }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("案件を公開しました")
      expect(json["job"]["status"]).to eq('published')

      draft_job.reload
      expect(draft_job.status).to eq('published')
      expect(draft_job.published_at).to be_present
    end

    it "returns error when publishing non-draft job" do
      post :publish, params: { id: published_job.uuid }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("draft 状態の案件のみ公開できます")
    end

    it "returns 403 when publishing as non-owner" do
      sign_in musician_user
      post :publish, params: { id: draft_job.uuid }

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for non-existent job" do
      post :publish, params: { id: 'non-existent-uuid' }
      expect(response).to have_http_status(:not_found)
    end
  end
end

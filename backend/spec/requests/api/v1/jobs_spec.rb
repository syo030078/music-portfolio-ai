require 'rails_helper'

RSpec.describe "Api::V1::Jobs", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /api/v1/jobs" do
    context "公開中の案件が存在する場合" do
      let!(:published_job1) { create(:job, status: 'published', published_at: 1.day.ago, client: user) }
      let!(:published_job2) { create(:job, status: 'published', published_at: 2.days.ago, client: other_user) }
      let!(:draft_job) { create(:job, status: 'draft', client: user) }

      it "公開中の案件のみ取得できる" do
        get "/api/v1/jobs"
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['jobs'].length).to eq(2)
        expect(json['jobs'].map { |j| j['uuid'] }).to contain_exactly(published_job1.uuid, published_job2.uuid)
      end

      it "新しい順でソートされている" do
        get "/api/v1/jobs"
        json = JSON.parse(response.body)
        expect(json['jobs'].first['uuid']).to eq(published_job1.uuid)
        expect(json['jobs'].second['uuid']).to eq(published_job2.uuid)
      end
    end

    context "ページネーション" do
      before do
        15.times { |i| create(:job, status: 'published', published_at: i.days.ago, client: user) }
      end

      it "デフォルトで10件取得できる" do
        get "/api/v1/jobs"
        json = JSON.parse(response.body)
        expect(json['jobs'].length).to eq(10)
        expect(json['pagination']['per_page']).to eq(10)
        expect(json['pagination']['total_count']).to eq(15)
        expect(json['pagination']['total_pages']).to eq(2)
      end

      it "page=2で次の5件を取得できる" do
        get "/api/v1/jobs", params: { page: 2 }
        json = JSON.parse(response.body)
        expect(json['jobs'].length).to eq(5)
        expect(json['pagination']['current_page']).to eq(2)
      end

      it "per_pageで件数を指定できる" do
        get "/api/v1/jobs", params: { per_page: 5 }
        json = JSON.parse(response.body)
        expect(json['jobs'].length).to eq(5)
      end

      it "per_pageは最大50件まで" do
        get "/api/v1/jobs", params: { per_page: 100 }
        json = JSON.parse(response.body)
        expect(json['pagination']['per_page']).to eq(50)
      end
    end

    context "フィルタリング" do
      let!(:job1) { create(:job, status: 'published', published_at: 1.day.ago, budget_min_jpy: 50000, budget_max_jpy: 100000, is_remote: true) }
      let!(:job2) { create(:job, status: 'published', published_at: 2.days.ago, budget_min_jpy: 100000, budget_max_jpy: 200000, is_remote: false) }

      it "budget_minでフィルタリングできる" do
        get "/api/v1/jobs", params: { budget_min: 80000 }
        json = JSON.parse(response.body)
        expect(json['jobs'].length).to eq(1)
        expect(json['jobs'].first['uuid']).to eq(job2.uuid)
      end

      it "budget_maxでフィルタリングできる" do
        get "/api/v1/jobs", params: { budget_max: 150000 }
        json = JSON.parse(response.body)
        expect(json['jobs'].length).to eq(1)
        expect(json['jobs'].first['uuid']).to eq(job1.uuid)
      end

      it "is_remoteでフィルタリングできる" do
        get "/api/v1/jobs", params: { is_remote: 'true' }
        json = JSON.parse(response.body)
        expect(json['jobs'].length).to eq(1)
        expect(json['jobs'].first['uuid']).to eq(job1.uuid)
      end
    end

    context "案件が存在しない場合" do
      it "空の配列を返す" do
        get "/api/v1/jobs"
        json = JSON.parse(response.body)
        expect(json['jobs']).to eq([])
        expect(json['pagination']['total_count']).to eq(0)
      end
    end
  end

  describe "GET /api/v1/jobs/:uuid" do
    let(:job) { create(:job, status: 'published', published_at: 1.day.ago, client: user) }

    it "案件詳細を取得できる" do
      get "/api/v1/jobs/#{job.uuid}"
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['job']['uuid']).to eq(job.uuid)
      expect(json['job']['title']).to eq(job.title)
      expect(json['job']['description']).to eq(job.description)
      expect(json['job']['client']['uuid']).to eq(user.uuid)
    end

    it "存在しない案件で404エラー" do
      get "/api/v1/jobs/invalid-uuid"
      expect(response).to have_http_status(:not_found)

      json = JSON.parse(response.body)
      expect(json['error']).to eq("案件が見つかりません")
    end
  end

  describe "POST /api/v1/jobs" do
    let(:valid_params) do
      {
        job: {
          title: "Test Job",
          description: "Test Description",
          budget_jpy: 100000,
          budget_min_jpy: 50000,
          budget_max_jpy: 150000,
          delivery_due_on: 30.days.from_now.to_date,
          is_remote: true,
          location_note: "Tokyo"
        }
      }
    end

    context "認証済みユーザー" do
      before { sign_in user }

      it "案件を作成できる" do
        expect {
          post "/api/v1/jobs", params: valid_params
        }.to change(Job, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['message']).to eq("案件を作成しました")
        expect(json['job']['title']).to eq("Test Job")
        expect(json['job']['status']).to eq('draft')
      end

      it "初期statusはdraft" do
        post "/api/v1/jobs", params: valid_params
        job = Job.last
        expect(job.status).to eq('draft')
        expect(job.published_at).to be_nil
      end
    end

    context "未認証ユーザー" do
      it "401エラーを返す" do
        post "/api/v1/jobs", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "バリデーションエラー" do
      before { sign_in user }

      it "titleがない場合422エラー" do
        invalid_params = valid_params.deep_dup
        invalid_params[:job][:title] = nil

        post "/api/v1/jobs", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json['error']).to include("Title")
      end

      it "descriptionがない場合422エラー" do
        invalid_params = valid_params.deep_dup
        invalid_params[:job][:description] = nil

        post "/api/v1/jobs", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /api/v1/jobs/:uuid" do
    let(:job) { create(:job, client: user, title: "Old Title") }
    let(:update_params) do
      {
        job: {
          title: "New Title",
          description: "New Description"
        }
      }
    end

    context "所有者として" do
      before { sign_in user }

      it "案件を更新できる" do
        patch "/api/v1/jobs/#{job.uuid}", params: update_params
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['message']).to eq("案件を更新しました")
        expect(json['job']['title']).to eq("New Title")

        job.reload
        expect(job.title).to eq("New Title")
      end
    end

    context "非所有者として" do
      before { sign_in other_user }

      it "403エラーを返す" do
        patch "/api/v1/jobs/#{job.uuid}", params: update_params
        expect(response).to have_http_status(:forbidden)

        json = JSON.parse(response.body)
        expect(json['error']).to eq("権限がありません")
      end
    end

    context "未認証ユーザー" do
      it "401エラーを返す" do
        patch "/api/v1/jobs/#{job.uuid}", params: update_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "バリデーションエラー" do
      before { sign_in user }

      it "不正な値で422エラー" do
        invalid_params = { job: { title: '' } }
        patch "/api/v1/jobs/#{job.uuid}", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /api/v1/jobs/:uuid" do
    let(:job) { create(:job, client: user) }

    context "所有者として" do
      before { sign_in user }

      it "案件を削除できる" do
        job_uuid = job.uuid
        expect {
          delete "/api/v1/jobs/#{job_uuid}"
        }.to change(Job, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq("案件を削除しました")
      end
    end

    context "非所有者として" do
      before { sign_in other_user }

      it "403エラーを返す" do
        delete "/api/v1/jobs/#{job.uuid}"
        expect(response).to have_http_status(:forbidden)

        json = JSON.parse(response.body)
        expect(json['error']).to eq("権限がありません")
      end
    end

    context "未認証ユーザー" do
      it "401エラーを返す" do
        delete "/api/v1/jobs/#{job.uuid}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/jobs/:uuid/publish" do
    let(:job) { create(:job, client: user, status: 'draft', published_at: nil) }

    context "所有者として" do
      before { sign_in user }

      it "案件を公開できる" do
        post "/api/v1/jobs/#{job.uuid}/publish"
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['message']).to eq("案件を公開しました")
        expect(json['job']['status']).to eq('published')

        job.reload
        expect(job.status).to eq('published')
      end

      it "published_atが設定される" do
        post "/api/v1/jobs/#{job.uuid}/publish"

        job.reload
        expect(job.published_at).not_to be_nil
        expect(job.published_at).to be_within(1.second).of(Time.current)
      end
    end

    context "非所有者として" do
      before { sign_in other_user }

      it "403エラーを返す" do
        post "/api/v1/jobs/#{job.uuid}/publish"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証ユーザー" do
      it "401エラーを返す" do
        post "/api/v1/jobs/#{job.uuid}/publish"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

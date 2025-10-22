require 'rails_helper'

RSpec.describe Api::V1::TracksController, type: :controller do
  describe "GET #index" do
    let(:user1) { User.create!(email: 'user1@example.com', password: 'password123', name: 'User One', bio: 'Musician 1') }
    let(:user2) { User.create!(email: 'user2@example.com', password: 'password123', name: 'User Two', bio: 'Musician 2') }

    before do
      # テストデータ作成
      Track.create!(
        user: user1,
        title: 'Rock Song',
        description: 'A great rock song',
        yt_url: 'https://www.youtube.com/watch?v=rock123',
        bpm: 120,
        key: 'C',
        genre: 'Rock'
      )
      Track.create!(
        user: user1,
        title: 'Pop Song',
        description: 'A catchy pop song',
        yt_url: 'https://www.youtube.com/watch?v=pop123',
        bpm: 100,
        key: 'G',
        genre: 'Pop'
      )
      Track.create!(
        user: user2,
        title: 'Jazz Song',
        description: 'A smooth jazz song',
        yt_url: 'https://www.youtube.com/watch?v=jazz123',
        bpm: 140,
        key: 'D',
        genre: 'Jazz'
      )
    end

    it "returns tracks list with pagination" do
      get :index
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["tracks"]).to be_an(Array)
      expect(json["tracks"].length).to eq(3)
      expect(json["pagination"]).to be_present
      expect(json["pagination"]["current_page"]).to eq(1)
      expect(json["pagination"]["total_count"]).to eq(3)
    end

    it "includes user information in tracks" do
      get :index
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      first_track = json["tracks"].first
      expect(first_track["user"]).to be_present
      expect(first_track["user"]["name"]).to be_present
      expect(first_track["user"]["bio"]).to be_present
    end

    it "filters by genre" do
      get :index, params: { genre: 'Rock' }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["tracks"].length).to eq(1)
      expect(json["tracks"].first["genre"]).to eq('Rock')
    end

    it "filters by BPM range (min)" do
      get :index, params: { bpm_min: 110 }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["tracks"].length).to eq(2) # Rock (120) and Jazz (140)
      json["tracks"].each do |track|
        expect(track["bpm"]).to be >= 110
      end
    end

    it "filters by BPM range (max)" do
      get :index, params: { bpm_max: 110 }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["tracks"].length).to eq(1) # Pop (100)
      json["tracks"].each do |track|
        expect(track["bpm"]).to be <= 110
      end
    end

    it "filters by BPM range (min and max)" do
      get :index, params: { bpm_min: 100, bpm_max: 120 }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["tracks"].length).to eq(2) # Pop (100) and Rock (120)
    end

    it "filters by key" do
      get :index, params: { key: 'C' }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["tracks"].length).to eq(1)
      expect(json["tracks"].first["key"]).to eq('C')
    end

    it "supports pagination with page parameter" do
      get :index, params: { page: 1, per_page: 2 }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["tracks"].length).to eq(2)
      expect(json["pagination"]["current_page"]).to eq(1)
      expect(json["pagination"]["per_page"]).to eq(2)
      expect(json["pagination"]["total_pages"]).to eq(2)
    end

    it "returns second page of results" do
      get :index, params: { page: 2, per_page: 2 }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["tracks"].length).to eq(1)
      expect(json["pagination"]["current_page"]).to eq(2)
    end

    it "limits per_page to maximum of 50" do
      get :index, params: { per_page: 100 }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["pagination"]["per_page"]).to eq(50)
    end
  end

  describe "GET #show" do
    let(:user) { User.create!(email: 'show@example.com', password: 'password123', name: 'Show User', bio: 'Test musician') }
    let(:track) do
      Track.create!(
        user: user,
        title: 'Test Track',
        description: 'Test description',
        yt_url: 'https://www.youtube.com/watch?v=test123',
        bpm: 120,
        key: 'C',
        genre: 'Rock'
      )
    end

    it "returns track detail with user information" do
      get :show, params: { id: track.id }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["track"]).to be_present
      expect(json["track"]["id"]).to eq(track.id)
      expect(json["track"]["title"]).to eq('Test Track')
      expect(json["track"]["user"]["name"]).to eq('Show User')
      expect(json["track"]["user"]["bio"]).to eq('Test musician')
    end

    it "returns 404 for non-existent track" do
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)

      json = JSON.parse(response.body)
      expect(json["error"]).to eq("楽曲が見つかりません")
    end
  end

  describe "POST #create" do
    let(:authenticated_user) { User.create!(email: 'auth@example.com', password: 'password123', name: 'Auth User') }

    before do
      # 認証済みユーザーとしてサインイン
      sign_in authenticated_user
    end

    context "when both audio_file and yt_url are missing" do
      it "returns bad request error" do
        post :create, params: {}
        expect(response).to have_http_status(:bad_request)

        json = JSON.parse(response.body)
        expect(json["data"]["error"]).to eq("音声ファイルまたはYouTube URLを指定してください")
      end
    end

    context "when yt_url is provided" do
      let(:test_user) { User.create!(email: 'test@example.com', password: 'password123', name: 'Test User') }

      before do
        test_user # ユーザーを作成
      end

      it "creates a track with YouTube URL" do
        post :create, params: { yt_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', title: 'Test Video' }
        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["message"]).to eq("YouTube動画を登録しました")
        expect(json["data"]["yt_url"]).to eq('https://www.youtube.com/watch?v=dQw4w9WgXcQ')
        expect(json["data"]["title"]).to eq('Test Video')
      end

      it "creates a track with default title when title is not provided" do
        post :create, params: { yt_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }
        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["data"]["title"]).to eq('Untitled')
      end

      it "returns error when yt_url is invalid" do
        post :create, params: { yt_url: 'invalid-url', title: 'Test' }
        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["data"]["error"]).to be_present
      end
    end

    context "when audio_file is provided" do
      let(:audio_file) { fixture_file_upload('test.wav', 'audio/wav') }

      before do
        allow(AnalyzerRunner).to receive(:call).and_return({
          bpm: 120,
          key: "C",
          genre: "Pop",
          file_path: "test.wav",
          status: "success"
        })
      end

      it "returns analysis result" do
        post :create, params: { audio_file: audio_file }
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["message"]).to eq("load_wav created")
        expect(json["data"]["bpm"]).to eq(120)
        expect(json["data"]["key"]).to eq("C")
      end
    end

    context "when analysis fails" do
      let(:audio_file) { fixture_file_upload('test.wav', 'audio/wav') }

      before do
        allow(AnalyzerRunner).to receive(:call).and_return({
          error: "音楽解析に失敗しました。ファイル形式を確認してください。"
        })
      end

      it "returns error with unprocessable_entity status" do
        post :create, params: { audio_file: audio_file }
        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["data"]["error"]).to be_present
      end
    end
  end
end
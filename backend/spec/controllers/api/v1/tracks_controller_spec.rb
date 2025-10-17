require 'rails_helper'

RSpec.describe Api::V1::TracksController, type: :controller do
  describe "GET #index" do
    it "returns ok status" do
      get :index
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["status"]).to eq("ok")
    end
  end

  describe "POST #create" do
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
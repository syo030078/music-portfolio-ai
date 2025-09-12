require 'rails_helper'

RSpec.describe Api::V1::TracksController, type: :controller do
  describe "GET #index" do
    it "returns load_wav message" do
      get :index
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("load_wav")
      expect(json["status"]).to eq("ok")
    end
  end

  describe "POST #create" do
    it "returns load_wav created message" do
      post :create, params: { title: "test song" }
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("load_wav created")
      expect(json["data"]).to be_present
    end
  end
end
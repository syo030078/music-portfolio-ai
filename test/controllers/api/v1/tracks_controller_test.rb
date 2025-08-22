require "test_helper"

class Api::V1::TracksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_tracks_index_url
    assert_response :success
  end

  test "should get show" do
    get api_v1_tracks_show_url
    assert_response :success
  end

  test "should get create" do
    get api_v1_tracks_create_url
    assert_response :success
  end
end

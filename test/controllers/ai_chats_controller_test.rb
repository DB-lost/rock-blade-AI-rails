require "test_helper"

class AiChatsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get ai_chats_index_url
    assert_response :success
  end
end

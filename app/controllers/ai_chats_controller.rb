class AiChatsController < ApplicationController
  before_action :set_chat_breadcrumbs

  def index
  end

  private

  def set_chat_breadcrumbs
    set_default_breadcrumb
    add_breadcrumb "AI Chats", ai_chats_path
  end
end

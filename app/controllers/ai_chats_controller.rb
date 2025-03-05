class AiChatsController < ApplicationController
  before_action :set_chat_breadcrumbs

  def index
    @assistants = current_user.assistants

    # 如果URL中有assistant_id参数，则使用该助手
    if params[:assistant_id].present?
      @current_assistant = current_user.assistants.find_by(id: params[:assistant_id])
      current_user.update(last_used_assistant: @current_assistant) if @current_assistant
    else
      @current_assistant = current_user.last_used_assistant
    end

    @current_conversation = @current_assistant&.conversations&.includes(:messages)&.ordered&.first
  end

  private

  def set_chat_breadcrumbs
    set_default_breadcrumb
    add_breadcrumb "AI Chats", ai_chats_path
  end
end

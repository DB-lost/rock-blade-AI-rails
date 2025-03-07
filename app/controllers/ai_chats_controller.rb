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

    # 如果选择了助手，检查是否有对话，没有则创建，有则获取最后一个
    if @current_assistant.present?
      conversation = @current_assistant.conversations.ordered.first
      if conversation.nil?
        # 创建新对话
        conversation = @current_assistant.conversations.create(
          title: "新对话 #{Time.current.strftime('%Y-%m-%d %H:%M')}",
          user: current_user
        )
      end
      @current_conversation = conversation
    end
    @conversations = @current_assistant.conversations.order(updated_at: :desc)
  end

  private

  def set_chat_breadcrumbs
    set_default_breadcrumb
    add_breadcrumb "AI Chats", ai_chats_path
  end
end

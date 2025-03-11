class ConversationsController < ApplicationController
  before_action :set_assistant
  before_action :set_conversation, only: [ :destroy ]

  def create
    @conversation = @assistant.conversations.build(conversation_params)

    if @conversation.save
      redirect_to ai_chats_path, notice: "对话创建成功"
    else
      redirect_to ai_chats_path, error: "对话创建失败"
    end
  end

  def update
    @conversation = @assistant.conversations.find(params[:id])
    if @conversation.update(conversation_params)
      redirect_to ai_chats_path, notice: "对话更新成功"
    else
      redirect_to ai_chats_path, error: "对话更新失败"
    end
  end

  def destroy
    if @conversation.destroy
      redirect_to ai_chats_path, notice: "对话已删除"
    else
      redirect_to ai_chats_path, error: "对话删除失败"
    end
  end

  private

  def conversation_params
    params.require(:conversation).permit(:title)
  end

  def set_assistant
    @assistant = Assistant.find(params[:assistant_id])
  end

  def set_conversation
    @conversation = @assistant.conversations.find(params[:id])
  end
end

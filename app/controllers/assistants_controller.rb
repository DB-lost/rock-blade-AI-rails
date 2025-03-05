class AssistantsController < ApplicationController
  before_action :set_assistant, only: [ :show, :edit, :update, :destroy, :duplicate, :clear_topics, :set_last_used ]

  def create
    @assistant = current_user.assistants.build(assistant_params)

    if @assistant.save
      redirect_to ai_chats_path, notice: "助手创建成功"
    else
      redirect_to ai_chats_path, status: :unprocessable_entity
    end
  end

  def update
    if @assistant.update(assistant_params)
      redirect_to ai_chats_path, notice: "助手更新成功"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assistant.destroy
    redirect_to ai_chats_path, notice: "助手已删除"
  end

  # 复制助手
  def duplicate
    new_assistant = @assistant.dup
    new_assistant.title = "#{@assistant.title} 副本"
    new_assistant.user = current_user

    if new_assistant.save
      render json: { success: true }, status: :ok
    else
      render json: { error: new_assistant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # 清空所有话题
  def clear_topics
    if @assistant.conversations.destroy_all
      render json: { success: true }, status: :ok
    else
      render json: { error: "清空话题失败" }, status: :unprocessable_entity
    end
  end

  # 设置最后使用的助手
  def set_last_used
    Current.user.update!(last_used_assistant: @assistant)
    head :ok
  end

  private

  def set_assistant
    @assistant = current_user.assistants.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to assistants_path, alert: "无法访问该助手"
  end

  def assistant_params
    params.require(:assistant).permit(:title, :instructions, :tool_choice, :tools)
  end
end

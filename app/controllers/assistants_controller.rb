class AssistantsController < ApplicationController
  before_action :set_assistant, only: [ :update, :destroy, :set_last_used ]

  def create
    @assistant = current_user.assistants.build(assistant_params)

    if @assistant.save
      Current.user.update!(last_used_assistant: @assistant)
      @assistant.conversations.create(
        title: "新对话 #{Time.current.strftime('%Y-%m-%d %H:%M')}",
        user: current_user
      )
      redirect_to ai_chats_path, notice: "助手创建成功"
    else
      raise StandardError.new("助手创建失败")
    end
  rescue StandardError => e
    handle_error(e)
  end

  def update
    if @assistant.update(assistant_params)
      redirect_to ai_chats_path, notice: "助手更新成功"
    else
      raise StandardError.new("助手更新失败")
    end
  rescue StandardError => e
    handle_error(e)
  end

  def destroy
    # 清除所有将此助手作为last_used_assistant的用户引用
    User.where(last_used_assistant: @assistant).update_all(last_used_assistant_id: nil)

    if @assistant.destroy
      respond_to do |format|
        format.html { redirect_to ai_chats_path, notice: "助手已删除" }
        format.json { head :ok }
      end
    else
      raise StandardError.new("助手删除失败")
    end
  rescue StandardError => e
    handle_error(e)
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

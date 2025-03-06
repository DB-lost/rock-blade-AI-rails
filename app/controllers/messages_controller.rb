class MessagesController < ApplicationController
  def create
    begin
      @conversation = Conversation.find(params.dig(:message, :conversation_id))
    rescue ActiveRecord::RecordNotFound
      raise StandardError.new("对话不存在")
    end

    # 构建并保存消息
    @message = @conversation.messages.build(message_params)
    @message.role = "user"

    if @message.save
      # 获取对话历史
      history = @conversation.messages.ordered.map do |msg|
        { role: msg.role, content: msg.content }
      end

      # 使用流式响应生成AI回复
      ai_service = AiChatService.new(@conversation.assistant)
      ai_service.generate_streaming_response(@conversation.id, history)

      respond_to do |format|
        format.turbo_stream { head :ok }
        format.html { redirect_to @conversation }
      end
    else
      raise StandardError.new(@message.errors.full_messages.join(", "))
    end
  rescue StandardError => e
    handle_error(e)
  end

  private

  def message_params
    params.require(:message).permit(:content, :conversation_id)
  end

  def handle_error(error)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "error_messages",
          partial: "shared/error_messages",
          locals: { errors: [ error.message ] }
        )
      end
      format.html { redirect_back fallback_location: root_path, alert: error.message }
    end
  end
end

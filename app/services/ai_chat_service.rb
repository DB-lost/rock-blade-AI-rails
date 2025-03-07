# frozen_string_literal: true

class AiChatService
  attr_reader :assistant

  def initialize(assistant)
    @assistant = assistant
  end

  # 流式生成响应，用于实时更新
  def generate_streaming_response(conversation_id, history)
    begin
      # 创建一个空的助手回复消息
      message = Message.create!(
        conversation_id: conversation_id,
        content: "正在思考...",
        role: "assistant"
      )

      # 启动后台任务
      GenerateAiResponseJob.perform_later(
        message.id,
        history,
        assistant.instructions
      )

      # 返回初始消息对象，让控制器可以立即返回响应
      message
    rescue => e
      Rails.logger.error("AI流式响应初始化错误: #{e.inspect}")

      # 创建错误消息
      Message.create!(
        conversation_id: conversation_id,
        content: "抱歉，我在处理您的请求时遇到了问题。请稍后再试。",
        role: "assistant"
      )
    end
  end
end

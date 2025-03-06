# frozen_string_literal: true

class GenerateAiResponseJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find(message_id)
    conversation = message.conversation
    assistant = conversation.assistant

    begin
      # 获取历史消息以提供上下文
      history = conversation.messages.order(created_at: :asc).map do |msg|
        { role: msg.role, content: msg.content }
      end

      # 使用AI服务生成回复
      ai_service = AiChatService.new(assistant)
      response = ai_service.generate_response(history)

      # 创建AI回复消息
      conversation.messages.create!(
        content: response,
        role: "assistant"
      )
    rescue => e
      Rails.logger.error("AI响应生成错误: #{e.inspect}")
      Rails.logger.error(e.backtrace.join("\n"))

      # 创建错误响应消息
      conversation.messages.create!(
        content: "抱歉，我在处理您的请求时遇到了问题。请稍后再试。",
        role: "assistant"
      )
    end
  end
end

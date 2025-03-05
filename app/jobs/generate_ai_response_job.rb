class GenerateAiResponseJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find(message_id)
    conversation = message.conversation
    assistant = conversation.assistant

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
      role: "assistant",
      assistant: assistant
    )
  end
end

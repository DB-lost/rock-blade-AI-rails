# frozen_string_literal: true

class AiChatService
  attr_reader :assistant, :langchain_assistant

  def initialize(assistant)
    @assistant = assistant
    @langchain_assistant = Langchain::Assistant.new(
      llm: assistant.llm,
      instructions: assistant.instructions
    )
  end

  def generate_response(history)
    begin
      # 清除之前的消息历史
      @langchain_assistant.clear_messages!

      # 添加历史消息
      history.each do |msg|
        @langchain_assistant.add_message(
          content: msg[:content],
          role: msg[:role]
        )
      end

      # 运行助手并获取响应
      @langchain_assistant.run

      # 获取最后一条消息的内容
      @langchain_assistant.messages.last&.content ||
        "抱歉，我在处理您的请求时遇到了问题。请稍后再试。"
    rescue => e
      Rails.logger.error("AI响应生成错误: #{e.inspect}")
      Rails.logger.error(e.backtrace.join("\n"))
      "抱歉，我在处理您的请求时遇到了问题。请稍后再试。"
    end
  end
end

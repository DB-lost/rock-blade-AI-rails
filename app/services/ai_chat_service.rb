class AiChatService
  attr_reader :assistant

  def initialize(assistant)
    @assistant = assistant
  end

  def generate_response(history)
    # 使用langchainrb和assistant的LLM进行推理
    llm = assistant.llm
    # 获取AI响应
    response = llm.chat(messages: history)
    response.dig("choices", 0, "message", "content")
  rescue => e
    Rails.logger.error("AI响应生成错误: #{e.message}")
    "抱歉，我在处理您的请求时遇到了问题。请稍后再试。"
  end

  private
end

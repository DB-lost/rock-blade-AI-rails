class AiChatService
  attr_reader :assistant

  def initialize(assistant)
    @assistant = assistant
  end

  def generate_response(history)
    # 使用langchainrb和assistant的LLM进行推理
    begin
      llm = assistant.llm

      # 将历史记录构建为prompt
      prompt = build_prompt(history)

      # 获取AI响应
      response = llm.complete(prompt: prompt)

      response
    rescue => e
      Rails.logger.error("AI响应生成错误: #{e.message}")
      "抱歉，我在处理您的请求时遇到了问题。请稍后再试。"
    end
  end

  private

  def build_prompt(history)
    # 构建适合模型的提示格式
    prompt_parts = []

    history.each do |msg|
      role = case msg[:role]
      when "system" then "system"
      when "user" then "user"
      when "assistant" then "assistant"
      else "user"
      end

      prompt_parts << "#{role}: #{msg[:content]}"
    end

    prompt_parts.join("\n")
  end
end

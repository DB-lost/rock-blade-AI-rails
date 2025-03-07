# frozen_string_literal: true

class AiChatService
  attr_reader :assistant, :langchain_assistant

  def initialize(assistant)
    @assistant = assistant
    @langchain_assistant = create_langchain_assistant
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

  private

  def setup_langchain_assistant(history)
    # 清除之前的消息历史
    @langchain_assistant.clear_messages!

    # 添加系统指令
    if assistant.instructions.present?
      @langchain_assistant.add_message(
        content: assistant.instructions,
        role: "system"
      )
    end

    # 添加历史消息，跳过系统消息
    history.each do |msg|
      next if msg[:role] == "system"
      @langchain_assistant.add_message(
        content: msg[:content],
        role: msg[:role]
      )
    end
  end

  def format_tool_calls(tool_calls)
    # 处理一个或多个工具调用
    tool_calls.map do |tool_call|
      function_name = tool_call.dig("function", "name")
      arguments = tool_call.dig("function", "arguments")
      arguments_text = arguments.is_a?(String) ? arguments.strip : JSON.pretty_generate(arguments)

      "正在执行工具: #{function_name}\n参数: #{arguments_text}"
    end.join("\n\n")
  end

  def update_message_safely(message_id, content)
    # 查找消息并更新（避免跨线程使用同一个AR对象）
    message_to_update = Message.find(message_id)
    message_to_update.update!(content: content)
    # 使用公共接口刷新UI
    message_to_update.refresh_in_ui
  rescue => e
    Rails.logger.error("更新消息失败: #{e.inspect}")
  end

  def handle_streaming_error(error, message_id)
    Rails.logger.error("AI响应生成错误: #{error.inspect}")
    Rails.logger.error(error.backtrace.join("\n"))

    # 查找消息并更新错误信息
    begin
      update_message_safely(
        message_id,
        "抱歉，我在处理您的请求时遇到了问题。请稍后再试。"
      )
    rescue => find_error
      Rails.logger.error("无法更新错误消息: #{find_error.inspect}")
    end
  end

  def create_langchain_assistant
    Langchain::Assistant.new(
      llm: LLMService.create_llm,
      instructions: @assistant.instructions || "你是一个功能齐全的AI助手，可以使用不同工具。",
      tools: AssistantToolsService.register_tools
    )
  end
end

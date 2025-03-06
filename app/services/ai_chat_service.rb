# frozen_string_literal: true

class AiChatService
  attr_reader :assistant, :langchain_assistant

  def initialize(assistant)
    @assistant = assistant
    @langchain_assistant = create_langchain_assistant
  end

  def generate_response(history)
    begin
      setup_langchain_assistant(history)

      # 运行助手并自动执行工具
      @langchain_assistant.run!

      # 获取最后一条消息的内容
      @langchain_assistant.messages.last&.content ||
        "抱歉，我在处理您的请求时遇到了问题。请稍后再试。"
    rescue => e
      Rails.logger.error("AI响应生成错误: #{e.inspect}")
      Rails.logger.error(e.backtrace.join("\n"))
      "抱歉，我在处理您的请求时遇到了问题。请稍后再试。"
    end
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

      # 保存message_id以便在线程中使用
      message_id = message.id

      # 运行助手并实时更新消息 - 使用线程安全的方式
      Thread.new do
        # 确保线程有自己的数据库连接
        ActiveRecord::Base.connection_pool.with_connection do
          begin
            setup_langchain_assistant(history)

            # 定义回调函数来处理流式响应
            add_message_callback = lambda do |msg|
              if msg.role == "assistant"
                content = if msg.tool_calls.present?
                  # 工具调用
                  format_tool_calls(msg.tool_calls)
                else
                  # 普通文本回复
                  msg.content.presence || "正在处理响应..."
                end

                # 更新消息内容
                update_message_safely(message_id, content)
              end
            end

            # 设置回调并运行助手
            @langchain_assistant.add_message_callback = add_message_callback
            @langchain_assistant.run!

            # 获取最终结果
            final_content = @langchain_assistant.messages.last&.content || "处理完成"
            update_message_safely(message_id, final_content)
          rescue => e
            handle_streaming_error(e, message_id)
          ensure
            # 确保连接返回到连接池
            ActiveRecord::Base.connection_pool.release_connection
          end
        end
      end

      message
    rescue => e
      Rails.logger.error("AI流式响应初始化错误: #{e.inspect}")
      Rails.logger.error(e.backtrace.join("\n"))

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

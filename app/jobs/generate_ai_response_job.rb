# frozen_string_literal: true

class GenerateAiResponseJob < ApplicationJob
  queue_as :default

  def perform(message_id, history, instructions)
    @message = Message.find(message_id)
    @tool_usages = {}  # 存储工具使用记录的引用

    begin
      setup_assistant(instructions, history)
      process_conversation
    rescue => e
      handle_error(e)
    end
  end

  private

  def setup_assistant(instructions, history)
    llm = LLMService.create_llm
    @langchain_assistant = Langchain::Assistant.new(
      llm: llm,
      instructions: instructions || "你是一个功能齐全的AI助手，可以使用不同工具。",
      tools: AssistantToolsService.register_tools,
      add_message_callback: method(:handle_assistant_message)
    )

    # 清除任何可能的历史消息
    @langchain_assistant.clear_messages!

    # 设置加载历史消息标记
    @loading_history = true

    # 添加历史消息，跳过系统消息
    history.each do |msg|
      next if msg[:role] == "system"
      @langchain_assistant.add_message(
        content: msg[:content],
        role: msg[:role]
      )
    end

    # 重置标记
    @loading_history = false
  end

  def process_conversation
    # 运行助手
    @langchain_assistant.run!

    # 获取最终结果
    final_content = @langchain_assistant.messages.last&.content || "处理完成"
    @message.update!(content: final_content)
    @message.refresh_in_ui
  end

  def handle_assistant_message(msg)
    return unless msg.role == "assistant"

    content = if msg.tool_calls.present?
      # 处理工具调用
      formatted_content = format_tool_calls(msg.tool_calls)
      # 更新工具使用状态
      update_tool_usage_status(msg.tool_calls, msg.content)
      formatted_content
    elsif !@loading_history  # 只在非加载历史时显示思考状态
      # 检查是否包含思考过程
      if msg.content =~ /<thinking>.*<\/thinking>/m
        "正在思考..."
      else
        msg.content.presence || "正在处理响应..."
      end
    else
      msg.content  # 历史消息直接显示内容
    end

    @message.update!(content: content) if content.present?
    @message.refresh_in_ui
  end

  def format_tool_calls(tool_calls)
    tool_calls.map do |tool_call|
      function_name = tool_call.dig("function", "name")
      arguments = tool_call.dig("function", "arguments")
      arguments_text = arguments.is_a?(String) ? arguments.strip : JSON.pretty_generate(arguments)

      # 创建工具使用记录并保存引用
      tool_usage = @message.tool_usages.create!(
        function_name: function_name,
        arguments: arguments,
        status: "pending"
      )

      # 存储工具使用记录的引用
      @tool_usages[tool_call["id"]] = tool_usage

      "正在执行工具: #{function_name}\n参数: #{arguments_text}"
    end.join("\n\n")
  end

  def update_tool_usage_status(tool_calls, result)
    tool_calls.each do |tool_call|
      if tool_usage = @tool_usages[tool_call["id"]]
        # 总是更新状态和结果
        status = result.present? ? "success" : "pending"
        result_text = result.presence || "等待执行结果"

        tool_usage.update!(
          status: status,
          result: result_text
        )
      end
    end
  end

  def handle_error(e)
    Rails.logger.error("流式响应生成错误: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    # 更新所有pending状态的工具使用记录为failed
    @message.tool_usages.where(status: "pending").update_all(
      status: "failed",
      result: "任务执行过程中发生错误: #{e.message}"
    )

    @message.update!(content: "抱歉，我在处理您的请求时遇到了问题。请稍后再试。")
    @message.refresh_in_ui
  end
end

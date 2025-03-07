# frozen_string_literal: true

class GenerateAiResponseJob < ApplicationJob
  queue_as :default

  def perform(message_id, history, instructions)
    message = Message.find(message_id)

    begin
      # 创建LLM和助手
      llm = LLMService.create_llm
      langchain_assistant = Langchain::Assistant.new(
        llm: llm,
        instructions: instructions || "你是一个功能齐全的AI助手，可以使用不同工具。",
        tools: AssistantToolsService.register_tools,
        add_message_callback: ->(msg) {
          if msg.role == "assistant"
            content = if msg.tool_calls.present?
              format_tool_calls(msg.tool_calls)
            else
              msg.content.presence || "正在处理响应..."
            end

            # 更新消息并刷新UI
            message.update!(content: content)
            message.refresh_in_ui
          end
        }
      )

      # 添加历史消息
      history.each do |msg|
        next if msg[:role] == "system"
        langchain_assistant.add_message(
          content: msg[:content],
          role: msg[:role]
        )
      end

      # 运行助手
      langchain_assistant.run!

      # 获取最终结果
      final_content = langchain_assistant.messages.last&.content || "处理完成"
      message.update!(content: final_content)
      message.refresh_in_ui

    rescue => e
      Rails.logger.error("流式响应生成错误: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      message.update!(content: "抱歉，我在处理您的请求时遇到了问题。请稍后再试。")
      message.refresh_in_ui
    end
  end

  private

  def format_tool_calls(tool_calls)
    tool_calls.map do |tool_call|
      function_name = tool_call.dig("function", "name")
      arguments = tool_call.dig("function", "arguments")
      arguments_text = arguments.is_a?(String) ? arguments.strip : JSON.pretty_generate(arguments)

      "正在执行工具: #{function_name}\n参数: #{arguments_text}"
    end.join("\n\n")
  end
end

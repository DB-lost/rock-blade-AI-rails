# frozen_string_literal: true

class GenerateAiResponseJob < ApplicationJob
  queue_as :default

  def perform(message_id, history, instructions, selected_tools = [])
    @message = Message.find(message_id)
    @tool_usages = {}  # 存储工具使用记录的引用
    @selected_tools = selected_tools  # 存储选中的工具

    # 初始化消息内容，避免显示上一次的回答
    @message.update!(content: "正在思考...")
    @message.refresh_in_ui

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
    tools = get_selected_tools  # 新增方法获取选中的工具
    @langchain_assistant = Langchain::Assistant.new(
      llm: llm,
      instructions: instructions || "你是一个功能齐全的AI助手，可以使用不同工具。",
      tools: tools,
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

    # 更新所有未完成的工具使用记录
    @tool_usages.each do |tool_id, tool_usage|
      if tool_usage.status == "pending"
        tool_usage.update!(
          status: "success",
          result: "工具执行完成"
        )
      end
    end

    @message.update!(content: final_content)
    @message.refresh_in_ui
  end

  def handle_assistant_message(msg)
    return unless msg.role == "assistant"

    # 如果是在加载历史消息，不进行任何更新
    return if @loading_history

    # 尝试获取工具调用信息
    tool_calls = nil
    tool_call_id = nil

    if msg.respond_to?(:tool_calls) && msg.tool_calls.present?
      tool_calls = msg.tool_calls
    end

    if msg.respond_to?(:tool_call_id) && msg.tool_call_id.present?
      tool_call_id = msg.tool_call_id
    end

    content = if tool_calls.present?
      # 处理工具调用
      formatted_content = format_tool_calls(tool_calls)
      # 更新工具使用状态 - 此时不传递结果，因为工具调用还在进行中
      update_tool_usage_status(tool_calls, nil)
      formatted_content
    else
      # 检查是否是工具调用的结果
      if tool_call_id.present? && @tool_usages[tool_call_id]

        # 更新特定工具调用的结果
        tool_usage = @tool_usages[tool_call_id]
        tool_usage.update!(
          status: "success",
          result: msg.content.to_s
        )
        # 返回原始内容，不更新消息
        return
      else
        # 所有其他情况都显示处理中
        "正在思考..."
      end
    end

    @message.update!(content: content) if content.present?
    @message.refresh_in_ui
  end

  def format_tool_calls(tool_calls)
    formatted_results = tool_calls.map do |tool_call|
      # 确保 tool_call 是一个哈希
      tool_call = tool_call.to_h if tool_call.respond_to?(:to_h)

      # 获取工具调用 ID
      tool_id = tool_call["id"] || tool_call[:id]

      # 获取函数名称和参数
      function = tool_call["function"] || tool_call[:function]
      function = function.to_h if function.respond_to?(:to_h)

      function_name = function["name"] || function[:name]
      arguments = function["arguments"] || function[:arguments]

      # 格式化参数文本
      arguments_text = if arguments.is_a?(String)
        arguments.strip
      elsif arguments.respond_to?(:to_json)
        JSON.pretty_generate(arguments)
      else
        arguments.to_s
      end

      begin
        # 创建工具使用记录并保存引用
        tool_usage = @message.tool_usages.create!(
          function_name: function_name,
          arguments: arguments.to_s,
          status: "pending"
        )

        # 存储工具使用记录的引用
        @tool_usages[tool_id] = tool_usage

        "正在执行工具: #{function_name}\n参数: #{arguments_text}"
      rescue => e
        Rails.logger.error("创建工具使用记录时出错: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        "执行工具时出错: #{function_name}"
      end
    end

    formatted_results.join("\n\n")
  end

  def update_tool_usage_status(tool_calls, result)
    tool_calls.each do |tool_call|
      # 确保 tool_call 是一个哈希
      tool_call = tool_call.to_h if tool_call.respond_to?(:to_h)

      # 获取工具调用 ID
      tool_id = tool_call["id"] || tool_call[:id]

      if tool_usage = @tool_usages[tool_id]

        begin
          # 如果结果为 nil，保持 pending 状态
          if result.nil?
            tool_usage.update!(
              status: "pending",
              result: "等待执行结果"
            )
          else
            # 有结果时更新为 success
            tool_usage.update!(
              status: "success",
              result: result.to_s
            )
          end
        rescue => e
          Rails.logger.error("更新工具使用记录时出错: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
        end
      else
        Rails.logger.warn("未找到工具使用记录: ID=#{tool_id}")
      end
    end
  end

  def get_selected_tools
    tools = AssistantToolsService.register_tools

    # 解析 selected_tools 参数
    selected_tool_types = []
    if @selected_tools.present?
      begin
        # 尝试解析 JSON 字符串
        if @selected_tools.is_a?(String)
          selected_tool_types = JSON.parse(@selected_tools)
        elsif @selected_tools.is_a?(Array)
          selected_tool_types = @selected_tools
        end
      rescue => e
        Rails.logger.error("解析 selected_tools 参数时出错: #{e.message}")
        Rails.logger.error("原始参数: #{@selected_tools.inspect}")
      end
    end

    # 添加网络搜索工具
    if selected_tool_types.include?("network")
      # 使用 Rails 凭证获取 API 密钥
      api_key = Rails.application.credentials.dig(:tools, :tavily_key)
      if api_key.present?
        tools << Langchain::Tool::Tavily.new(api_key: api_key)
      else
        Rails.logger.warn("未找到 Tavily API 密钥，无法添加网络搜索工具")
      end
    end

    # 添加知识库工具
    if selected_tool_types.include?("knowledge")
      # 这里可以添加知识库工具的实现
    end

    tools
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

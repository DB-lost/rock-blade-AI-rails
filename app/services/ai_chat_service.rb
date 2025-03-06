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

      # 添加系统指令
      if assistant.instructions.present?
        @langchain_assistant.add_message(
          content: assistant.instructions,
          role: "system"
        )
      end

      # 添加历史消息，跳过系统消息，因为我们已经添加了指令
      history.each do |msg|
        next if msg[:role] == "system"
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

  # 流式生成响应，用于实时更新
  def generate_streaming_response(conversation_id, history)
    begin
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

      # 创建一个空的助手回复消息（content设为nil，不是空字符串，以避开验证）
      message = Message.create!(
        conversation_id: conversation_id,
        content: nil,
        role: "assistant"
      )

      # 保存message_id以便在线程中使用
      message_id = message.id

      # 运行助手并实时更新消息 - 使用线程安全的方式
      Thread.new do
        # 确保线程有自己的数据库连接
        ActiveRecord::Base.connection_pool.with_connection do
          begin
            response = @langchain_assistant.run
            final_content = @langchain_assistant.messages.last&.content || "抱歉，我在处理您的请求时遇到了问题。"

            # 查找消息并更新（避免跨线程使用同一个AR对象）
            message_to_update = Message.find(message_id)
            message_to_update.update!(content: final_content)
            # 使用公共接口刷新UI，而不是直接调用私有方法
            message_to_update.refresh_in_ui
          rescue => e
            Rails.logger.error("AI流式响应生成错误: #{e.inspect}")
            Rails.logger.error(e.backtrace.join("\n"))

            # 查找消息并更新错误信息
            begin
              message_to_update = Message.find(message_id)
              message_to_update.update!(content: "抱歉，我在处理您的请求时遇到了问题。请稍后再试。")
              # 使用公共接口刷新UI
              message_to_update.refresh_in_ui
            rescue => find_error
              Rails.logger.error("无法更新错误消息: #{find_error.inspect}")
            end
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
end

class MessagesController < ApplicationController
  def create
    begin
      @conversation = Conversation.find(params.dig(:message, :conversation_id))
    rescue ActiveRecord::RecordNotFound
      raise StandardError.new("对话不存在")
    end

    # 3. 构建并保存消息
    @message = @conversation.messages.build(message_params)
    @message.role = "user"

    if @message.save
      GenerateAiResponseJob.perform_later(@message.id)
      head :ok
    else
      raise StandardError.new(@message.errors.full_messages.join(", "))
    end
  rescue StandardError => e
    handle_error(e)
  end

  private

  def message_params
    params.require(:message).permit(:content, :conversation_id)
  end
end

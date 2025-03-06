class MessagesController < ApplicationController
  before_action :set_conversation

  def create
    @message = @conversation.messages.build(message_params)
    @message.role = "user"
    @message.assistant = @conversation.assistant

    if @message.save
      GenerateAiResponseJob.perform_later(@message.id)
      head :ok
    else
      raise StandardError.new("failed to create message")
    end
  rescue StandardError => e
    handle_error(e)
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end

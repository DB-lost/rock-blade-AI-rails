class ConversationsController < ApplicationController
  before_action :set_assistant, only: [ :create, :index ]
  before_action :set_conversation, only: [ :show ]

  def index
    @conversations = @assistant.conversations.order(updated_at: :desc)
  end

  def show
    @messages = @conversation.messages
  end

  def create
    @conversation = @assistant.conversations.build(conversation_params)

    if @conversation.save
      redirect_to assistant_conversation_path(@assistant, @conversation)
    else
      raise StandardError.new("对话创建失败")
    end
  rescue StandardError => e
    handle_error(e)
  end

  private

  def set_assistant
    @assistant = Assistant.find(params[:assistant_id])
  end

  def set_conversation
    @conversation = Conversation.find(params[:id])
    @assistant = @conversation.assistant
  end

  def conversation_params
    params.require(:conversation).permit(:title)
  end
end

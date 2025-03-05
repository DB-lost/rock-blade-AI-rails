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
      @conversations = @assistant.conversations.order(updated_at: :desc)
      render "assistants/show", status: :unprocessable_entity
    end
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

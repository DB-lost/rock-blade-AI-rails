class AssistantsController < ApplicationController
  def index
    @assistants = Assistant.all
  end

  def show
    @assistant = Assistant.find(params[:id])
    @conversations = @assistant.conversations.order(updated_at: :desc)
    @conversation = @assistant.conversations.build
  end
end

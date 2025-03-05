# frozen_string_literal: true

class Message < ActiveRecord::Base
  belongs_to :assistant
  belongs_to :conversation

  validates :content, presence: true
  validates :role, presence: true

  after_create_commit -> { broadcast_create }

  private

  def broadcast_create
    broadcast_append_to(
      "conversation_#{conversation_id}",
      target: "conversation_messages",
      partial: "messages/#{role}_message",
      locals: { message: self }
    )
  end
end

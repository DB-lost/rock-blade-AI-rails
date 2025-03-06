# frozen_string_literal: true

class Message < ActiveRecord::Base
  belongs_to :conversation

  validates :content, presence: true, unless: :assistant_with_pending_response?
  validates :role, presence: true, inclusion: { in: %w[system assistant user] }

  scope :ordered, -> { order(created_at: :asc) }
  delegate :assistant, to: :conversation

  after_create_commit -> { broadcast_create }
  after_update_commit -> { broadcast_replace }

  def system?
    role == "system"
  end

  def user?
    role == "user"
  end

  def assistant?
    role == "assistant"
  end

  def assistant_with_pending_response?
    assistant? && content.nil?
  end

  def refresh_in_ui
    broadcast_replace_to(
      "conversation_#{conversation_id}",
      target: self,
      partial: "messages/#{role}_message",
      locals: { message: self }
    )
  end

  private

  def broadcast_create
    broadcast_append_to(
      "conversation_#{conversation_id}",
      target: "conversation_messages",
      partial: "messages/#{role}_message",
      locals: { message: self }
    )
  end

  def broadcast_replace
    broadcast_replace_to(
      "conversation_#{conversation_id}",
      target: self,
      partial: "messages/#{role}_message",
      locals: { message: self }
    )
  end
end

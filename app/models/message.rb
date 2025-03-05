# frozen_string_literal: true

class Message < ActiveRecord::Base
  belongs_to :conversation

  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: %w[system assistant user] }

  scope :ordered, -> { order(created_at: :asc) }
  delegate :assistant, to: :conversation

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

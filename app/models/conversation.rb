class Conversation < ApplicationRecord
  belongs_to :assistant
  belongs_to :user, optional: true
  has_many :messages, -> { order(created_at: :asc) }, dependent: :destroy

  validates :title, presence: true

  after_create :create_initial_message

  private

  def create_initial_message
    messages.create(
      role: "system",
      content: assistant.system_message || "你好，我是#{assistant.name}，请问有什么我可以帮助你的？",
      assistant: assistant
    )
  end
end

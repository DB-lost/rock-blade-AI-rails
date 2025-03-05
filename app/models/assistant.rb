# frozen_string_literal: true

class Assistant < ActiveRecord::Base
  belongs_to :user
  has_many :messages, dependent: :destroy
  has_many :conversations, dependent: :destroy

  def llm
    Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
  end
end

# frozen_string_literal: true

class Assistant < ActiveRecord::Base
  has_many :messages

  def llm
    Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
  end
end

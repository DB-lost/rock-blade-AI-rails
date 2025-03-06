# frozen_string_literal: true

class Assistant < ActiveRecord::Base
  vectorsearch

  after_save :upsert_to_vectorsearch

  belongs_to :user
  has_many :messages, dependent: :destroy
  has_many :conversations, dependent: :destroy

  def llm
    LLMService.create_llm()
  end
end

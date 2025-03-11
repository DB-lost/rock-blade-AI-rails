# frozen_string_literal: true

class Assistant < ActiveRecord::Base
  belongs_to :user
  has_many :conversations, dependent: :destroy

  def llm
    LLMService.create_llm()
  end
end

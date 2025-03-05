# frozen_string_literal: true

require_relative "../../app/services/llm_service"

LangchainrbRails.configure do |config|
  config.vectorsearch = Langchain::Vectorsearch::Qdrant.new(
    url: LLMService.qdrant_url,
    api_key: LLMService.qdrant_api_key,
    llm: LLMService.create_llm,
    index_name: "ai_pro_cgc"
  )
end

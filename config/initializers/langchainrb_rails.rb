# frozen_string_literal: true

require_relative "../../app/services/llm_service"

LangchainrbRails.configure do |config|
  config.vectorsearch = Langchain::Vectorsearch::Qdrant.new(
    url: LLMService.qdrant_url,
    api_key: LLMService.qdrant_api_key,
    llm: LLMService.create_llm,
    index_name: "rock_blade_ai_rails"
  )

  config.configure_model ContentChunk do |model|
    model.embedding_field = :content
    model.searchable_attributes = [ :content ]
    model.collection_name = "content_chunks"
  end
end

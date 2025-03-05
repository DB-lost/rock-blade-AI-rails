# frozen_string_literal: true

LangchainrbRails.configure do |config|
  config.vectorsearch = Langchain::Vectorsearch::Qdrant.new(
    llm: Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"]),
    url: ENV["QDRANT_URL"],
    api_key: ENV["QDRANT_API_KEY"],
    index_name: ""
  )
end

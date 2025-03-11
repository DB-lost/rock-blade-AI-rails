# frozen_string_literal: true

require "langchain/llm/doubao"

# Service class for handling LLM (Language Learning Model) configuration
class LLMService
  class << self
    def create_llm
      Rails.env.production? ? create_doubao_llm : create_doubao_llm
    end

    def qdrant_url
      Rails.env.production? ? Rails.application.credentials.dig(:qdrant, :url) : "http://localhost:6333"
    end

    def qdrant_api_key
      Rails.env.production? ? Rails.application.credentials.dig(:qdrant, :api_key) : nil
    end

    private

    def create_doubao_llm
      Langchain::LLM::Doubao.new(
        api_key: Rails.application.credentials.dig(:doubao, :ARK_API_KEY),
        default_options: doubao_options
      )
    end

    def create_ollama_llm
      Langchain::LLM::Ollama.new
    end

    def doubao_options
      {
        chat_model: Rails.application.credentials.dig(:doubao, :ARK_DOUBAO_1_5_PRO_32K_MODEL),
        embedding_model: Rails.application.credentials.dig(:doubao, :ARK_DOUBAO_EMBEDDING_LARGE_MODEL),
        dimensions: 2560
      }
    end
  end
end

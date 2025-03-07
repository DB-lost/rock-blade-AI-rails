require "securerandom"

# 开始将 Doubao 类包装在模块中
module Langchain
  module LLM
    # LLM interface for Doubao APIs
    # Usage:
    #    doubao = Langchain::LLM::Doubao.new(
    #      api_key: ENV["DOUBAO_API_KEY"],
    #      llm_options: {
    #        uri_base: 'https://ark.cn-beijing.volces.com/api',
    #        api_version: 'v3'
    #      },
    #      default_options: {
    #        chat_model: ENV["DOUBAO_CHAT_MODEL"],
    #        embedding_model: ENV["DOUBAO_EMBEDDING_MODEL"]
    #      }
    #    )
    class Doubao < OpenAI
      DEFAULTS = {
        n: 1,
        temperature: 0.0,
        chat_model: "doubao-pro-256k",
        embedding_model: "doubao-embeddings"
      }.freeze

      EMBEDDING_SIZES = {
        "doubao-pro-256k" => 2560,
        "doubao-embeddings" => 2560
      }.freeze

      def initialize(api_key:, llm_options: {}, default_options: {})
        llm_options[:uri_base] ||= "https://ark.cn-beijing.volces.com/api"
        llm_options[:api_version] ||= "v3"

        @defaults = DEFAULTS.merge(default_options)
        super(api_key: api_key, llm_options: llm_options, default_options: @defaults)
      end

      def chat(params = {}, &block)
        if params[:messages]
          params = params.dup
          params[:messages] = params[:messages].map do |msg|
            msg = msg.dup
            if msg[:content].is_a?(Array)
              msg[:content] = msg[:content].map { |c| c[:text] }.join("\n")
            end

            # 确保工具调用消息有 tool_call_id 参数
            if msg[:role] == "tool" && msg[:tool_call_id].nil?
              msg[:tool_call_id] = SecureRandom.uuid
            end

            msg
          end
        end

        super(params, &block)
      end

      def default_dimensions
        @defaults[:dimensions] || EMBEDDING_SIZES.fetch(@defaults[:embedding_model])
      end

      def embed(text:, model: @defaults[:embedding_model], encoding_format: nil, user: nil, dimensions: @defaults[:dimensions])
        raise ArgumentError.new("text argument is required") if text.empty?
        raise ArgumentError.new("model argument is required") if model.empty?

        parameters = {
          input: text,
          model: model
        }
        parameters[:encoding_format] = encoding_format if encoding_format
        parameters[:user] = user if user

        if dimensions
          parameters[:dimensions] = dimensions
        elsif EMBEDDING_SIZES.key?(model)
          parameters[:dimensions] = EMBEDDING_SIZES[model]
        end

        response = with_api_error_handling do
          client.embeddings(parameters: parameters)
        end

        Langchain::LLM::OpenAIResponse.new(response)
      end

      private

      def with_api_error_handling
        response = yield
        return if response.empty?

        raise Langchain::LLM::ApiError.new("Doubao API error: #{response.dig('error', 'message')}") if response&.dig("error")
        response
      end
    end
  end  # 结束模块 LLM
end  # 结束模块 Langchain

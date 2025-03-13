# frozen_string_literal: true

module Langchain::Tool
  #
  # 知识库搜索工具
  #
  # 这个工具用于在知识库中搜索相关内容。它能够在多个知识库中进行搜索，
  # 并返回最相关的内容片段。
  #
  # Usage:
  #    knowledge_base_tool = Langchain::Tool::KnowledgeBase.new
  #    knowledge_base_tool.setup_context([knowledge_base1, knowledge_base2])
  #
  class KnowledgeBase
    extend Langchain::ToolDefinition

    define_function :search, description: "在知识库中搜索相关内容" do
      property :query, type: "string", description: "要搜索的查询内容", required: true
      property :limit, type: "integer", description: "每个知识库返回的最大结果数。默认值: 3"
    end

    # 初始化知识库搜索工具
    #
    # @param knowledge_bases [Array<KnowledgeBase>] 要搜索的知识库列表
    def setup_context(knowledge_bases)
      @knowledge_bases = knowledge_bases
    end

    # 在知识库中执行搜索
    #
    # @param query [String] 搜索查询
    # @param limit [Integer] 每个知识库返回的最大结果数
    # @return [Langchain::Tool::Response] 搜索结果响应
    def search(query:, limit: 3)
      return tool_response(content: "未选择知识库或参数不正确") if @knowledge_bases.blank? || query.blank?
      results = []
      @knowledge_bases.each do |kb|
        begin
          matches = kb.knowledge_entries.flat_map do |entry|
            entry.content_chunks.similarity_search(query, k: limit)
          end
          next if matches.empty?
          results << "来自知识库 #{kb.name}:\n#{format_matches(matches)}"
        rescue => e
          Rails.logger.error("知识库搜索错误: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
        end
      end
      content = results.any? ? results.join("\n\n") : "未找到相关内容"
      tool_response(content: content)
    end

    private

    def format_matches(matches)
      matches.map { |match| match.content }.join("\n---\n")
    end
  end
end

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
      property :limit, type: "integer", description: "每个知识库返回的最大结果数。默认值: 10"
      property :min_score, type: "number", description: "最小相似度分数阈值，范围0-1。默认不设置阈值"
      property :adaptive_limit, type: "boolean", description: "是否启用自适应limit调整。默认: true"
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
    # @param min_score [Float] 最小相似度分数阈值，范围0-1
    # @param adaptive_limit [Boolean] 是否启用自适应limit调整
    # @return [Langchain::Tool::Response] 搜索结果响应
    def search(query:, limit: 10, min_score: nil, adaptive_limit: true)
      return tool_response(content: "未选择知识库或参数不正确") if @knowledge_bases.blank? || query.blank?

      results = []
      @knowledge_bases.each do |kb|
        begin
          # 如果启用自适应limit，先尝试较小的limit
          if adaptive_limit
            # 先尝试较小的limit (3)
            initial_limit = 3
            matches = search_with_limit(kb, query, initial_limit, min_score)

            # 如果结果不足且limit小于请求的limit，逐步增加limit
            if matches.empty? && initial_limit < limit
              Rails.logger.info("知识库搜索: 初始limit=#{initial_limit}未找到结果，尝试增加limit=#{limit}")
              matches = search_with_limit(kb, query, limit, min_score)
            end
          else
            # 不启用自适应limit，直接使用指定的limit
            matches = search_with_limit(kb, query, limit, min_score)
          end

          next if matches.empty?

          # 记录搜索结果的相似度分数
          if matches.first.respond_to?(:score)
            scores = matches.map { |m| m.score.round(4) }
            Rails.logger.info("知识库搜索: 查询='#{query}', 知识库='#{kb.name}', 相似度分数=#{scores}")
          end

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

    # 使用指定的limit在知识条目中搜索
    # @param kb [KnowledgeBase] 知识库
    # @param query [String] 搜索查询
    # @param limit [Integer] 最大结果数
    # @param min_score [Float] 最小相似度分数阈值
    # @return [Array] 匹配结果
    def search_with_limit(kb, query, limit, min_score)
      kb.knowledge_entries.flat_map do |entry|
        entry.content_chunks.similarity_search(
          query,
          k: limit,
          min_score: min_score
        )
      end
    end

    def format_matches(matches)
      matches.map do |match|
        content = match.content
        if match.respond_to?(:score)
          "【相似度: #{(match.score * 100).round(2)}%】#{content}"
        else
          content
        end
      end.join("\n---\n")
    end
  end
end

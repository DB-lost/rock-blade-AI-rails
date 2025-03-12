class KnowledgeBaseService
  attr_reader :user, :assistant, :selected_knowledge_bases

  def initialize(user, assistant = nil, selected_knowledge_base_ids = [])
    @user = user
    @assistant = assistant
    @selected_knowledge_bases = if selected_knowledge_base_ids.present?
                                  user.knowledge_bases.where(id: selected_knowledge_base_ids)
    else
                                  []
    end
  end

  # 使用向量搜索知识库内容
  def search(query, limit = 5)
    return [] if query.blank? || @selected_knowledge_bases.empty?

    results = []
    @selected_knowledge_bases.each do |knowledge_base|
      # 对每个选中的知识库进行向量搜索
      entries = VectorSearchService.search_in_knowledge_base(knowledge_base.id, query, limit: limit)

      entries.each do |entry|
        results << {
          id: entry[:id],
          title: entry[:title],
          content: entry[:content],
          source_type: entry[:source_type],
          knowledge_base: knowledge_base.name,
          score: entry[:score]
        }
      end
    end

    # 按相似度分数排序并限制结果数量
    results.sort_by { |result| -result[:score] }.first(limit)
  end

  # 获取知识库内容用于AI上下文
  def get_context_for_ai(query, max_tokens = 2000)
    search_results = search(query, 3)

    # 构建上下文
    context = "以下是来自知识库的相关信息：\n\n"

    search_results.each_with_index do |result, index|
      context += "【#{index + 1}】#{result[:title]}\n"
      context += "来源：#{result[:knowledge_base]}\n"
      context += "内容：#{truncate_content(result[:content], max_tokens / search_results.size)}\n\n"
    end

    context
  end

  private

  def truncate_content(content, max_length)
    return "" if content.blank?

    if content.length <= max_length
      content
    else
      content[0...max_length] + "..."
    end
  end
end

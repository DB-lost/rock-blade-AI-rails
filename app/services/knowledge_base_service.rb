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

  # 搜索知识库内容
  def search(query, limit = 5)
    return [] if query.blank? || @selected_knowledge_bases.empty?

    # 简单实现：基于关键词搜索
    # 未来可以替换为向量搜索或其他语义搜索方法
    results = []

    @selected_knowledge_bases.each do |knowledge_base|
      # 搜索知识条目
      entries = knowledge_base.knowledge_entries
                             .where("title ILIKE ? OR content ILIKE ?", "%#{query}%", "%#{query}%")
                             .limit(limit)

      entries.each do |entry|
        results << {
          id: entry.id,
          title: entry.title,
          content: entry.content,
          source_type: entry.source_type,
          source_url: entry.source_url,
          knowledge_base: knowledge_base.name
        }
      end
    end

    # 按相关性排序（简单实现）
    results.sort_by do |result|
      # 标题匹配的优先级高于内容匹配
      [
        -(result[:title].downcase.include?(query.downcase) ? 1 : 0),
        -(result[:content].to_s.downcase.include?(query.downcase) ? 1 : 0)
      ]
    end.first(limit)
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

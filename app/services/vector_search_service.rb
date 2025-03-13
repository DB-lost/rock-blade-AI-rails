# frozen_string_literal: true

class VectorSearchService
  class << self
    def search_in_knowledge_base(knowledge_base_id, query, limit: 5)
      # 在内容块中进行向量搜索
      chunks = ContentChunk.search_by_embedding(
        query,
        limit: limit * 2, # 获取更多块以便找到最相关的条目
        where: { "metadata.knowledge_base_id" => knowledge_base_id }
      )

      # 按条目 ID 分组并找到相关的知识条目
      entry_ids = chunks.map { |chunk| chunk.metadata["entry_id"] }.uniq
      entries = KnowledgeEntry.where(id: entry_ids)

      # 为每个条目组织相关的文本块
      entries.map do |entry|
        relevant_chunks = chunks.select { |chunk| chunk.metadata["entry_id"] == entry.id }
                               .sort_by(&:sequence)
        # 使用最高相似度作为条目的分数
        best_score = relevant_chunks.map(&:_search_score).max

        {
          id: entry.id,
          title: entry.title,
          content: entry.content,
          source_type: entry.source_type,
          chunks: relevant_chunks.map do |chunk|
            {
              content: chunk.content,
              sequence: chunk.sequence,
              score: chunk._search_score
            }
          end,
          score: best_score
        }
      end.sort_by { |result| -result[:score] }.first(limit)
    end

    def reindex_all
      ContentChunk.reindex
    rescue => e
      Rails.logger.error "Error reindexing vectors: #{e.message}"
      false
    end
  end
end

# frozen_string_literal: true

class VectorSearchService
  class << self
    def search_in_knowledge_base(knowledge_base_id, query, limit: 5)
      entries = KnowledgeEntry.search_by_embedding(
        query,
        limit: limit,
        where: { knowledge_base_id: knowledge_base_id }
      )

      entries.map do |entry|
        {
          id: entry.id,
          title: entry.title,
          content: entry.content,
          source_type: entry.source_type,
          score: entry._search_score
        }
      end
    end

    def reindex_all
      KnowledgeEntry.reindex
    rescue => e
      Rails.logger.error "Error reindexing vectors: #{e.message}"
      false
    end
  end
end

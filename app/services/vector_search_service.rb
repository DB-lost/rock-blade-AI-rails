# frozen_string_literal: true

class VectorSearchService
  class << self
    def search_knowledge_entries(query, limit: 5)
      KnowledgeEntry.search_by_embedding(query, limit: limit)
    end

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
    end

    def update_entry_vectors(entry)
      entry.update_vector_embeddings
    end
  end
end

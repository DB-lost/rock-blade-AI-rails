class ContentChunk < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  # 关联
  belongs_to :knowledge_entry

  # 验证
  validates :content, presence: true
  validates :sequence, presence: true
  validates :metadata, presence: true

  # 排序
  scope :ordered, -> { order(sequence: :asc) }

  def process_for_embeddings
    {
      content: content,
      metadata: metadata.merge(
        entry_id: knowledge_entry_id,
        sequence: sequence
      )
    }
  end
end

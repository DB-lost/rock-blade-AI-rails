# frozen_string_literal: true

class ContentChunk < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch
  after_destroy :destroy_from_vectorsearch

  # 关联
  belongs_to :knowledge_entry

  # 验证
  validates :content, presence: true
  validates :sequence, presence: true
  validates :metadata, presence: true

  # 排序
  scope :ordered, -> { order(sequence: :asc) }

  # 定义如何序列化为向量
  def as_vector
    content
  end
end

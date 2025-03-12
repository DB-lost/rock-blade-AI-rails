class KnowledgeBase < ApplicationRecord
  # 解决单复数问题
  self.table_name = "knowledge_bases"

  # 关联
  belongs_to :user
  has_many :knowledge_entries, dependent: :destroy

  # 验证
  validates :name, presence: true

  # 搜索范围
  scope :search, ->(query) { where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%") if query.present? }
end

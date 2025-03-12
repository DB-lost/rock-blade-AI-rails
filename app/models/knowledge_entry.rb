class KnowledgeEntry < ApplicationRecord
  include LangchainrbRails::Vectorizable

  # 关联
  belongs_to :knowledge_base

  # 文件附件
  has_one_attached :file

  # 验证
  validates :title, presence: true
  validates :source_type, presence: true
  validates :source_url, presence: true, if: -> { url? }
  validates :content, presence: true, if: -> { note? }
  validates :file, presence: true, if: -> { file? }

  # 排序
  scope :ordered, -> { order(created_at: :desc) }

  # 搜索
  scope :search, ->(query) { where("title ILIKE ? OR content ILIKE ?", "%#{query}%", "%#{query}%") if query.present? }

  # 类型判断方法
  def url?
    source_type == "url"
  end

  def note?
    source_type == "note"
  end

  def file?
    source_type == "file"
  end

  # 关联
  has_many :content_chunks, dependent: :destroy

  # 回调
  after_commit :process_async, on: :create

  private

  def process_async
    ProcessKnowledgeEntryJob.perform_later(id)
  end
end

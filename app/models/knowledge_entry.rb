class KnowledgeEntry < ApplicationRecord
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

  # 处理文件内容提取
  after_create :extract_content_from_file, if: -> { file? && file.attached? }

  private

  def extract_content_from_file
    # 这里将来实现文件内容提取逻辑
    # 根据文件类型（PDF, DOCX, TXT等）提取文本内容
    # 并存储到content字段中
  end
end

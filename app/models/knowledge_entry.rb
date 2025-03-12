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

  # 处理文件内容提取
  after_create :extract_content_from_file, if: -> { file? && file.attached? }
  def process_for_embeddings
    {
      title: title,
      content: content,
      metadata: {
        source_type: source_type,
        knowledge_base_id: knowledge_base_id
      }
    }
  end

  private

  def extract_content_from_file
    return unless file.attached?

    content = case file.content_type
    when "text/markdown", "text/plain"
               file.download
    when "application/pdf"
               extract_pdf_content
    when %r{\Aimage/.*}
               extract_image_content
    else
               Rails.logger.warn "Unsupported file type: #{file.content_type}"
               nil
    end

    update(content: content) if content.present?
  end

  def extract_pdf_content
    require "pdf-reader"

    io = file.download
    reader = PDF::Reader.new(io)
    reader.pages.map(&:text).join("\n\n")
  rescue => e
    Rails.logger.error "Error extracting PDF content: #{e.message}"
    nil
  end

  def extract_image_content
    # 使用多邦AI进行图片描述
    image_wrapper = Langchain::Utils::ImageWrapper.new(
      Rails.application.routes.url_helpers.rails_blob_url(file, host: ENV["HOST"])
    )

    LLMService.create_llm.complete(
      prompt: "请描述这张图片的内容：",
      image: image_wrapper.base64
    )
  rescue => e
    Rails.logger.error "Error extracting image content: #{e.message}"
    nil
  end
end

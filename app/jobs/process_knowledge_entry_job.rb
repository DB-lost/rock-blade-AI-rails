# frozen_string_literal: true


class ProcessKnowledgeEntryJob < ApplicationJob
  queue_as :default

  def perform(entry_id)
    entry = KnowledgeEntry.find(entry_id)
    return unless entry

    entry.update(status: "processing")

    begin
      processed_content = process_content(entry)
      if processed_content
        entry.update(content: processed_content)
        store_chunks(entry, processed_content)
        entry.update(status: "ready", processed_at: Time.current)
      else
        entry.update(status: "failed", metadata: { error: "无法处理文件内容" })
      end
    rescue => e
      Rails.logger.error "处理知识条目时出错: #{e.message}"
      entry.update(status: "failed", metadata: { error: e.message })
    end
  end

  private

  def process_content(entry)
    case entry.source_type
    when "note", "url"
      entry.content
    when "file"
      return unless entry.file.attached?

      # 获取文件的临时路径
      temp_file = download_to_tempfile(entry.file)

      # 使用 Langchain 的处理器
      processor = create_processor(entry.file.content_type, temp_file.path)
      content = processor&.parse(temp_file)

      temp_file.close
      temp_file.unlink

      content
    end
  rescue => e
    Rails.logger.error "处理文件内容时出错: #{e.message}"
    nil
  end

  def create_processor(content_type, file_path)
    case content_type
    when "application/pdf"
      Langchain::Processors::PDF.new(file_path)
    when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      Langchain::Processors::DOCX.new(file_path)
    when "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      Langchain::Processors::PPTX.new(file_path)
    when "text/markdown", "text/plain"
      Langchain::Processors::Text.new(file_path)
    when "text/html"
      Langchain::Processors::HTML.new(file_path)
    when %r{\Aimage/.*}
      process_image(file_path)
    else
      Rails.logger.warn "不支持的文件类型: #{content_type}"
      nil
    end
  end

  def process_image(file_path)
    # 对于图片，我们使用 LLM 生成描述
    image_wrapper = Langchain::Utils::ImageWrapper.new(file_path)

    description = LLMService.create_llm.complete(
      prompt: "请描述这张图片的内容：",
      image: image_wrapper.base64
    )

    # 返回一个简单的文本处理器
    Langchain::Processors::Text.new(description)
  end

  def download_to_tempfile(file)
    ext = File.extname(file.filename.to_s)
    tempfile = Tempfile.new([ "document", ext ])
    tempfile.binmode
    tempfile.write(file.download)
    tempfile.rewind
    tempfile
  end

  def store_chunks(entry, content)
    chunker = Langchain::Chunker::Text.new(
      content,
      chunk_size: 1000,
      chunk_overlap: 200
    )

    # 先清除旧的分块
    entry.content_chunks.destroy_all

    chunker.chunks.each_with_index do |chunk, index|
      entry.content_chunks.create!(
        content: chunk.text,
        sequence: index,
        metadata: {
          source_type: entry.source_type,
          knowledge_base_id: entry.knowledge_base_id
          #file_type: entry.file_type,
          #original_filename: entry.original_filename
        }
      )
    end
  end
end

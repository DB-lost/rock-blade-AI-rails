# frozen_string_literal: true

class ProcessKnowledgeEntryJob < ApplicationJob
  queue_as :default

  def perform(entry_id)
    entry = KnowledgeEntry.find(entry_id)
    return unless entry

    processed_content = process_content(entry)
    store_chunks(entry, processed_content) if processed_content
  end

  private

  def process_content(entry)
    case entry.source_type
    when "note", "url"
      entry.content
    when "file"
      return unless entry.file.attached?

      case entry.file.content_type
      when "text/markdown", "text/plain"
        entry.file.download
      when "application/pdf"
        extract_pdf_content(entry.file)
      when %r{\Aimage/.*}
        extract_image_content(entry.file)
      else
        Rails.logger.warn "Unsupported file type: #{entry.file.content_type}"
        nil
      end
    end
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
        }
      )
    end
  end

  def extract_pdf_content(file)
    require "pdf-reader"

    io = file.download
    reader = PDF::Reader.new(io)
    reader.pages.map(&:text).join("\n\n")
  rescue => e
    Rails.logger.error "Error extracting PDF content: #{e.message}"
    nil
  end

  def extract_image_content(file)
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

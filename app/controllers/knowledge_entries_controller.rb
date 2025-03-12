class KnowledgeEntriesController < ApplicationController
  before_action :set_knowledge_base
  before_action :set_knowledge_entry, only: [ :update, :destroy ]

  def create
    @knowledge_entry = @knowledge_base.knowledge_entries.new(knowledge_entry_params)

    if @knowledge_entry.save
      redirect_to @knowledge_base, notice: "知识条目添加成功。"
    else
      render @knowledge_base, status: :unprocessable_entity
    end
  end

  def update
    if @knowledge_entry.update(knowledge_entry_params)
      redirect_to @knowledge_base, notice: "知识条目更新成功。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @knowledge_entry.destroy
    redirect_to @knowledge_base, notice: "知识条目已删除。"
  end

  # 文件上传处理
  def upload_file
    @knowledge_entry = @knowledge_base.knowledge_entries.new(
      title: file_params[:file].original_filename,
      source_type: :file
    )
    @knowledge_entry.file.attach(file_params[:file])

    if @knowledge_entry.save
      render json: {
        success: true,
        message: "文件上传成功",
        redirect_url: knowledge_base_path(@knowledge_base)
      }
    else
      render json: {
        success: false,
        message: "文件上传失败：#{@knowledge_entry.errors.full_messages.join(', ')}"
      }
    end
  end

  # URL添加处理
  def add_url
    @knowledge_entry = @knowledge_base.knowledge_entries.new(
      title: url_params[:title],
      source_type: :url,
      source_url: url_params[:source_url]
    )

    if @knowledge_entry.save
      redirect_to @knowledge_base, notice: "URL添加成功。"
    else
      redirect_to @knowledge_base, alert: "URL添加失败：#{@knowledge_entry.errors.full_messages.join(', ')}"
    end
  end

  # 笔记添加处理
  def add_note
    @knowledge_entry = @knowledge_base.knowledge_entries.new(
      title: note_params[:title],
      source_type: :note,
      content: note_params[:content]
    )

    if @knowledge_entry.save
      redirect_to @knowledge_base, notice: "笔记添加成功。"
    else
      redirect_to @knowledge_base, alert: "笔记添加失败：#{@knowledge_entry.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_knowledge_base
    @knowledge_base = current_user.knowledge_bases.find(params[:knowledge_base_id])
  end

  def set_knowledge_entry
    @knowledge_entry = @knowledge_base.knowledge_entries.find(params[:id])
  end

  def knowledge_entry_params
    params.require(:knowledge_entry).permit(:title, :content, :source_type, :source_url, :file)
  end

  def file_params
    params.require(:knowledge_entry).permit(:file)
  end

  def url_params
    params.require(:knowledge_entry).permit(:title, :source_url)
  end

  def note_params
    params.require(:knowledge_entry).permit(:title, :content)
  end
end

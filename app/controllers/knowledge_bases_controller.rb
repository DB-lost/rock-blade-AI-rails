class KnowledgeBasesController < ApplicationController
  before_action :set_chat_breadcrumbs
  before_action :set_knowledge_base, only: [ :update, :destroy ]

  def list
    @knowledge_bases = current_user.knowledge_bases.order(created_at: :desc)
    render partial: "knowledge_bases/knowledge_base_list"
  end

  def index
    @knowledge_bases = current_user.knowledge_bases.order(created_at: :desc)

    # 搜索功能
    if params[:query].present?
      @knowledge_bases = @knowledge_bases.search(params[:query])
    end

    # 设置当前选中的知识库
    if params[:kb_id].present?
      @current_knowledge_base = @knowledge_bases.find_by(id: params[:kb_id])
      if @current_knowledge_base
        # 获取并按类型分组知识条目
        @knowledge_entries = @current_knowledge_base.knowledge_entries.order(created_at: :desc)
        @files = @knowledge_entries.select { |entry| entry.source_type == "file" }
        @directories = @knowledge_entries.select { |entry| entry.source_type == "directory" }
        @urls = @knowledge_entries.select { |entry| entry.source_type == "url" }
        @notes = @knowledge_entries.select { |entry| entry.source_type == "note" }
      end
    end
  end

  def create
    @knowledge_base = current_user.knowledge_bases.new(knowledge_base_params)

    if @knowledge_base.save
      redirect_to knowledge_bases_path, notice: "知识库创建成功。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @knowledge_base.update(knowledge_base_params)
      redirect_to knowledge_bases_path, notice: "知识库更新成功。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @knowledge_base.destroy
    redirect_to knowledge_bases_path, notice: "知识库已删除。"
  end

  private

  def set_knowledge_base
    @knowledge_base = current_user.knowledge_bases.find(params[:id])
  end

  def knowledge_base_params
    params.require(:knowledge_base).permit(:name, :description)
  end

  def set_chat_breadcrumbs
    add_breadcrumb "Knowledge Bases", knowledge_bases_path
  end
end

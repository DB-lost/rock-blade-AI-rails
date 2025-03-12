class KnowledgeBasesController < ApplicationController
  before_action :set_knowledge_base, only: [ :show, :edit, :update, :destroy ]

  def index
    @knowledge_bases = current_user.knowledge_bases.order(created_at: :desc)

    # 搜索功能
    if params[:query].present?
      @knowledge_bases = @knowledge_bases.search(params[:query])
    end

    # 分页
    @knowledge_bases = @knowledge_bases.page(params[:page]).per(10)
  end

  def show
    @knowledge_entries = @knowledge_base.knowledge_entries.ordered

    # 搜索功能
    if params[:query].present?
      @knowledge_entries = @knowledge_entries.search(params[:query])
    end

    # 分页
    @knowledge_entries = @knowledge_entries.page(params[:page]).per(20)
  end

  def new
    @knowledge_base = current_user.knowledge_bases.new
  end

  def create
    @knowledge_base = current_user.knowledge_bases.new(knowledge_base_params)

    if @knowledge_base.save
      redirect_to @knowledge_base, notice: "知识库创建成功。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @knowledge_base.update(knowledge_base_params)
      redirect_to @knowledge_base, notice: "知识库更新成功。"
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
    set_default_breadcrumb
    add_breadcrumb "Knowledge Bases", knowledge_bases_path
  end
end

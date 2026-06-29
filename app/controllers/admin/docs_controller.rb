# frozen_string_literal: true

class Admin::DocsController < AdminController
  before_action :set_doc, only: [:show, :edit, :update, :destroy]

  def index
    @docs = Doc.active.order(created_at: :desc)
  end

  def new
    @doc = Doc.new(status: :published)
  end

  def create
    @doc = Doc.new(doc_params)

    if @doc.save
      redirect_to admin_doc_path(@doc), notice: "資料を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @doc_downloads = @doc.doc_downloads
                           .includes(:doc_line_user)
                           .order(first_visited_at: :desc, created_at: :desc)
  end

  def edit
  end

  def update
    if @doc.update(doc_params)
      redirect_to admin_doc_path(@doc), notice: "資料を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @doc.soft_delete!
    redirect_to admin_docs_path, notice: "資料を削除しました"
  end

  private

  def set_doc
    @doc = Doc.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_docs_path, alert: "資料が見つかりません"
  end

  def doc_params
    params.require(:doc).permit(:status, :title, :description, :document_url, :thumbnail)
  end
end

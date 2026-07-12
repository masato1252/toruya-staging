# frozen_string_literal: true

class Admin::DocsController < AdminController
  before_action :set_doc, only: [:show, :edit, :update, :destroy]

  def index
    if ENV["COMPAT_API_READ_ENABLED"] == "true"
      @docs = []
      return
    end

    @docs = Doc.active.order(created_at: :desc)
  end

  def new
    @doc = Doc.new(status: :published)
  end

  def create
    return compat_create if ENV["COMPAT_API_READ_ENABLED"] == "true"

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
    return compat_update if ENV["COMPAT_API_READ_ENABLED"] == "true"

    if @doc.update(doc_params)
      redirect_to admin_doc_path(@doc), notice: "資料を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    return compat_destroy if ENV["COMPAT_API_READ_ENABLED"] == "true"

    @doc.soft_delete!
    redirect_to admin_docs_path, notice: "資料を削除しました"
  end

  private

  def set_doc
    return if ENV["COMPAT_API_READ_ENABLED"] == "true"

    @doc = Doc.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_docs_path, alert: "資料が見つかりません"
  end

  def doc_params
    params.require(:doc).permit(:status, :title, :description, :document_url, :thumbnail)
  end

  def compat_create
    render_compat_doc_response(compat_doc_request(Net::HTTP::Post, "/admin/docs"))
  end

  def compat_update
    render_compat_doc_response(compat_doc_request(Net::HTTP::Put, "/admin/docs/#{params[:id]}"))
  end

  def compat_destroy
    render_compat_doc_response(
      compat_v1_json_response(Net::HTTP::Delete, "/admin/docs/#{params[:id]}")
    )
  end

  def compat_doc_payload
    doc_params.except(:thumbnail).to_h
  end

  def compat_doc_request(request_class, path)
    thumbnail = doc_params[:thumbnail]
    return compat_v1_multipart_response(request_class, path, compat_doc_payload, thumbnail: thumbnail) if thumbnail.present?

    compat_v1_json_response(request_class, path, compat_doc_payload)
  end

  def render_compat_doc_response(response)
    unless response
      return redirect_to admin_docs_path, alert: "資料の保存に失敗しました" if request.format.html?

      render json: { status: "failed", error_message: "資料の保存に失敗しました" }, status: :bad_gateway
      return
    end

    if request.format.html?
      redirect_to response[:body]["redirect_to"].presence || admin_docs_path,
                  notice: "資料を保存しました"
      return
    end

    render json: response[:body], status: response[:status]
  end
end

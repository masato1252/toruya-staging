# frozen_string_literal: true

class Lines::UserBot::SalesController < Lines::UserBotDashboardController
  include CrossAccountRedirect
  redirect_to_correct_owner_for :sale_pages, only: [:edit, :update, :destroy, :clone]

  def new
    if compat_read_data_plane?
      render :new_compat
      return
    end
  end

  def index
    if compat_read_enabled?
      @sale_pages = []
      return
    end

    @sale_pages = Current.business_owner.sale_pages.includes(:product).order("updated_at DESC")
  end

  def show
    if compat_read_enabled?
      render :show_compat
      return
    end

    @sale_page = Current.business_owner.sale_pages.find_by(id: params[:id])
    @sale_page ||= Current.business_owner.sale_pages.find_by(slug: params[:id])
  end

  def edit
    if compat_read_data_plane?
      render :edit_compat
      return
    end

    @sale_page = Current.business_owner.sale_pages.find(params[:id])
  end

  def update
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      result = compat_v1_put(
        "/lines/user_bot/owner/#{owner_id}/sales/#{params[:id]}",
        params.permit!.to_h
      )
      render json: result || { status: "failed", error_message: "販売ページを更新できませんでした" },
             status: (result&.dig("status") == "successful" ? :ok : :unprocessable_entity)
      return
    end

    sale_page = Current.business_owner.sale_pages.find(params[:id])

    outcome = SalePages::Update.run(sale_page: sale_page, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_sale_path(sale_page.id, business_owner_id: business_owner_id, anchor: params[:attribute]) })
  end

  def destroy
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      result = compat_v1_delete("/lines/user_bot/owner/#{owner_id}/sales/#{params[:id]}")

      if result&.dig("status") == "successful"
        redirect_to lines_user_bot_sales_path(business_owner_id: owner_id), notice: I18n.t("common.delete_successfully_message")
      else
        redirect_to lines_user_bot_sales_path(business_owner_id: owner_id)
      end
      return
    end

    sale_page = Current.business_owner.sale_pages.find(params[:id])

    if sale_page.update(deleted_at: Time.current)
      redirect_to lines_user_bot_sales_path(business_owner_id: business_owner_id), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_sales_path(business_owner_id: business_owner_id)
    end
  end

  def clone
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      result = compat_v1_post("/lines/user_bot/owner/#{owner_id}/sales/#{params[:id]}/clone", {})
      if result&.dig("status") == "successful"
        redirect_to result["redirect_to"], notice: I18n.t("common.create_successfully_message")
      else
        redirect_to lines_user_bot_sale_path(params[:id], business_owner_id: owner_id),
                    alert: result&.dig("error_message")
      end
      return
    end

    sale_page = Current.business_owner.sale_pages.find(params[:id])

    outcome = SalePages::Clone.run(sale_page: sale_page)

    if outcome.valid?
      flash[:notice] = I18n.t("common.create_successfully_message")
      redirect_to lines_user_bot_sale_path(outcome.result, business_owner_id: business_owner_id)
    else
      redirect_to lines_user_bot_sale_path(sale_page, business_owner_id: business_owner_id)
    end
  end
end
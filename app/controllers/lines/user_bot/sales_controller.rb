# frozen_string_literal: true

class Lines::UserBot::SalesController < Lines::UserBotDashboardController
  def new
  end

  def index
    @sale_pages = current_user.sale_pages.includes(:product).order("updated_at DESC")
  end

  def show
    @sale_page = current_user.sale_pages.find(params[:id])
  end

  def edit
    @sale_page = current_user.sale_pages.find(params[:id])
  end

  def update
    sale_page = current_user.sale_pages.find(params[:id])

    outcome = SalePages::Update.run(sale_page: sale_page, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_sale_path(sale_page.id, anchor: params[:attribute]) })
  end

  def destroy
    sale_page = current_user.sale_pages.find(params[:id])

    if sale_page.update(deleted_at: Time.current)
      redirect_to lines_user_bot_sales_path, notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_sales_path
    end
  end
end

# frozen_string_literal: true

class Lines::UserBot::SalesController < Lines::UserBotDashboardController
  def new
  end

  def index
    @sale_pages = Current.business_owner.sale_pages.includes(:product).order("updated_at DESC")
  end

  def show
    @sale_page = Current.business_owner.sale_pages.find_by(id: params[:id])
    @sale_page ||= Current.business_owner.sale_pages.find_by(slug: params[:id])
  end

  def edit
    @sale_page = Current.business_owner.sale_pages.find(params[:id])
  end

  def update
    sale_page = Current.business_owner.sale_pages.find(params[:id])

    outcome = SalePages::Update.run(sale_page: sale_page, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_sale_path(sale_page.id, business_owner_id: business_owner_id, anchor: params[:attribute]) })
  end

  def destroy
    sale_page = Current.business_owner.sale_pages.find(params[:id])

    if sale_page.update(deleted_at: Time.current)
      redirect_to lines_user_bot_sales_path(business_owner_id: business_owner_id), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_sales_path(business_owner_id: business_owner_id)
    end
  end

  def clone
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
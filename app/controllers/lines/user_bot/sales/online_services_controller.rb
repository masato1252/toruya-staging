# frozen_string_literal: true

class Lines::UserBot::Sales::OnlineServicesController < Lines::UserBotDashboardController
  def new
    @sale_templates = SaleTemplate.where(locale: Current.business_owner.locale).order("id")

    if sale_page = SalePage.find_by(id: params[:sale_page_id])
      @selected_online_service = OnlineServiceSerializer.new(sale_page.product).attributes_hash
      @selected_template = sale_page.sale_template.attributes.slice("id", "edit_body", "view_body")
      @sale_page = sale_page.serializer.attributes_hash
    elsif service = OnlineService.find_by(slug: params[:slug])
      @selected_online_service = OnlineServiceSerializer.new(service).attributes_hash
    end
  end

  def create
    args = {
      user: Current.business_owner,
      id: params[:id],
      selected_online_service_id: params[:selected_online_service_id],
      selected_template_id: params[:selected_template_id],
      template_variables: params[:template_variables]&.permit!.to_h,
      content: params[:content]&.permit!.to_h&.transform_values! { |v| v.presence },
      staff: params[:staff]&.permit!&.to_h,
      introduction_video_url: params[:introduction_video_url],
      draft: params[:draft]
    }

    args[:selling_price] = params[:selling_price] if params[:selling_price].present?
    args[:normal_price] = params[:normal_price] if params[:normal_price].present?
    args[:selling_end_at] = params[:selling_end_at] if params[:selling_end_at].present?
    args[:quantity] = params[:quantity] if params[:quantity].present?
    args[:monthly_price] = params[:monthly_price] if params[:monthly_price].present?
    args[:yearly_price] = params[:yearly_price] if params[:yearly_price].present?

    if params[:selling_multiple_times_price].present?
      args[:selling_multiple_times_price] = Array.new(
        params[:selling_multiple_times_price][:times].to_i,
        params[:selling_multiple_times_price][:amount].to_i
      )
    end

    outcome = ::Sales::OnlineServices::Create.run(args)

    return_json_response(outcome, { sale_page_id: outcome.result&.slug, redirect_to: lines_user_bot_sales_path})
  end
end

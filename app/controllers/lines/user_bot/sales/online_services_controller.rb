# frozen_string_literal: true

class Lines::UserBot::Sales::OnlineServicesController < Lines::UserBotDashboardController
  def new
    @sale_templates = SaleTemplate.all

    if service = OnlineService.find_by(slug: params[:slug])
      @selected_online_service = OnlineServiceSerializer.new(service).attributes_hash
    end
  end

  def create
    args = {
      user: current_user,
      selected_online_service_id: params[:selected_online_service_id],
      selected_template_id: params[:selected_template_id],
      template_variables: params[:template_variables].permit!.to_h,
      content: params[:content].permit!.to_h,
      staff: params[:staff].permit!.to_h,
      introduction_video_url: params[:introduction_video_url]
    }

    args[:selling_price] = params[:selling_price] if params[:selling_price].present?
    args[:normal_price] = params[:normal_price] if params[:normal_price].present?
    args[:selling_end_at] = params[:selling_end_at] if params[:selling_end_at].present?
    args[:quantity] = params[:quantity] if params[:quantity].present?

    outcome = ::Sales::OnlineServices::Create.run(args)

    return_json_response(outcome, { sale_page_id: outcome.result&.slug })
  end
end

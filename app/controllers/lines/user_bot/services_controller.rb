# frozen_string_literal: true

class Lines::UserBot::ServicesController < Lines::UserBotDashboardController
  def new
  end

  def create
    outcome = ::OnlineServices::Create.run(
      user: current_user,
      name: params[:name],
      selected_goal: params[:selected_goal],
      selected_solution: params[:selected_solution],
      end_time: params[:end_time].permit!.to_h,
      upsell: params[:upsell].permit!.to_h,
      content_url: params[:content_url],
      selected_company: params[:selected_company].permit!.to_h,
    )

    return_json_response(outcome, { online_service_slug: outcome.result&.slug })
  end

  def index
    @online_services = current_user.online_services.order("updated_at DESC")
  end

  def show
    @service = current_user.online_services.find(params[:id])
    @upsell_sale_page = @service.sale_page.serializer.attributes_hash if @service.sale_page
    @online_service_hash = OnlineServiceSerializer.new(@service).attributes_hash.merge(demo: false, light: false)
    @registers_count = @service.online_service_customer_relations.uncanceled.count
  end

  def edit
    @service = current_user.online_services.find(params[:id])
    @attribute = params[:attribute]
  end

  def update
    service = current_user.online_services.find(params[:id])

    outcome = OnlineServices::Update.run(online_service: service, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_service_path(service.id, anchor: params[:attribute]) })
  end
end

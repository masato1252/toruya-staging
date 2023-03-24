# frozen_string_literal: true

class Lines::UserBot::ServicesController < Lines::UserBotDashboardController
  def new
  end

  def create
    outcome = ::OnlineServices::Create.run(
      user: Current.business_owner,
      name: params[:name],
      selected_goal: params[:selected_goal],
      selected_solution: params[:selected_solution],
      end_time: params[:end_time]&.permit!&.to_h,
      upsell: params[:upsell]&.permit!&.to_h,
      content_url: params[:content_url],
      external_purchase_url: params[:external_purchase_url],
      selected_company: params[:selected_company].permit!.to_h,
      message_template: params[:message_template]&.permit!&.to_h,
      bundled_services: params[:bundled_services]&.map { |s| s&.permit!&.to_h }
    )

    return_json_response(outcome, { online_service_slug: outcome.result&.slug })
  end

  def index
    @online_services = Current.business_owner.online_services.order("updated_at DESC")
  end

  def show
    @service = Current.business_owner.online_services.find(params[:id])
    @upsell_sale_page = @service.sale_page.serializer.attributes_hash if @service.sale_page
    @registers_count = @service.online_service_customer_relations.uncanceled.count

    if @service.course_like?
      @lessons_count = @service.lessons.count
      @chapters_count = @service.chapters.count
      @course_hash = CourseSerializer.new(@service, { params: { is_owner: true }}).attributes_hash
    elsif @service.membership?
      @episodes_count = @service.episodes.count
    else
      @online_service_hash = OnlineServiceSerializer.new(@service).attributes_hash.merge(demo: false, light: false)
    end
  end

  def edit
    @service = Current.business_owner.online_services.find(params[:id])
    @attribute = params[:attribute]
  end

  def update
    service = Current.business_owner.online_services.find(params[:id])

    outcome = OnlineServices::Update.run(online_service: service, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_service_path(service.id, anchor: params[:attribute]) })
  end
end

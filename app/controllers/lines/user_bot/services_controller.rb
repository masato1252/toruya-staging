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
      message_template: params[:message_template]&.permit!&.to_h,
      bundled_services: params[:bundled_services]&.map { |s| s&.permit!&.to_h }
    )

    return_json_response(outcome, { online_service_slug: outcome.result&.slug })
  end

  def index
    @online_services_with_sale_page_ids = Current.business_owner.sale_pages.for_online_service.pluck(:product_id)
    @online_services_with_draft_sale_page_ids = Current.business_owner.sale_pages.for_online_service.with_draft.group_by(&:product_id)
    @online_services = Current.business_owner.online_services.not_deleted.order("updated_at DESC")
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

    @sale_pages = SalePage.active.where(product: @service).order(:updated_at)
  end

  def edit
    @service = Current.business_owner.online_services.find(params[:id])
    @attribute = params[:attribute]
  end

  def update
    service = Current.business_owner.online_services.find(params[:id])

    outcome = OnlineServices::Update.run(online_service: service, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_service_path(service.id, business_owner_id: service.user_id, anchor: params[:attribute]) })
  end

  def destroy
    service = Current.business_owner.online_services.find(params[:id])
    outcome = OnlineServices::Delete.run(online_service: service)

    if outcome.valid?
      redirect_to lines_user_bot_services_path(business_owner_id: Current.business_owner.id)
    else
      flash[:alert] = outcome.errors.full_messages.join(", ")
      redirect_back(fallback_location: lines_user_bot_service_path(business_owner_id: service.user_id, id: service.id))
    end
  end
end

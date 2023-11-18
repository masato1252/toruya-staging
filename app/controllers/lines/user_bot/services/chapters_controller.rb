# frozen_string_literal: true

class Lines::UserBot::Services::ChaptersController < Lines::UserBotDashboardController
  def index
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @course_hash = CourseSerializer.new(@online_service, { params: { is_owner: true }}).attributes_hash
  end

  def new
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @chapter = @online_service.chapters.new

    render action: :edit
  end

  def edit
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @chapter = @online_service.chapters.find(params[:id])
  end

  def create
    online_service = Current.business_owner.online_services.find(params[:service_id])

    outcome = Chapters::Create.run(
      online_service: online_service,
      name: params[:name]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_service_chapters_path(params[:service_id], business_owner_id: params[:business_owner_id]) })
  end

  def update
    online_service = Current.business_owner.online_services.find(params[:service_id])
    chapter = online_service.chapters.find(params[:id])

    outcome = Chapters::Update.run(
      chapter: chapter,
      name: params[:name]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_service_chapters_path(params[:service_id], business_owner_id: params[:business_owner_id]) })
  end

  def destroy
    online_service = Current.business_owner.online_services.find(params[:service_id])
    chapter = online_service.chapters.find(params[:id])

    outcome = Chapters::Delete.run(chapter: chapter)

    if outcome.invalid?
      flash[:alert] = outcome.errors.full_messages.join(", ")
    end

    redirect_to lines_user_bot_service_chapters_path(params[:service_id], business_owner_id: params[:business_owner_id])
  end

  def reorder
    # {
    #   "items" => [
    #     {
    #       "chapter_id" => "chapter_15",
    #       "id" => 15,
    #       "lessons" => [
    #         31,
    #         30,
    #         32
    #       ]
    #     },
    #   ],
    #   "service_id" => "148",
    # }
    outcome = Chapters::Reorder.run(
      online_service: Current.business_owner.online_services.find(params[:service_id]),
      items: params.permit!.to_h[:items]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_service_chapters_path(params[:service_id], business_owner_id: params[:business_owner_id]) })
  end
end

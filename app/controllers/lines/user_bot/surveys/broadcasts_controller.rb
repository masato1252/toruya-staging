# frozen_string_literal: true

class Lines::UserBot::Surveys::BroadcastsController < Lines::UserBotDashboardController
  before_action :set_survey
  before_action :set_activity

  def show
    @broadcast = Current.business_owner.broadcasts.find(params[:id])
    @customers = Broadcasts::FilterCustomers.run!(broadcast: @broadcast)
    @broadcast.update(customers_permission_warning: @customers.any? { |customer| !customer.reminder_permission })
  end

  def new
    @candidate_customers = SurveyResponse.where(survey_activity_id: @activity.id).map { |survey_response|
      {
        id: survey_response.owner_id,
        name: survey_response.owner.name,
        state: survey_response.state,
        checked: params[:receiver_ids] ? params[:receiver_ids].include?(survey_response.owner_id) : true
      }
    }
    @broadcast = Broadcast.new(
      query: {},
      query_type: "manual_assignment",
      content: "",
      builder: @activity
    )
  end

  def edit
    @broadcast = Current.business_owner.broadcasts.find(params[:id])
    @attribute = params[:attribute]
    @survey_activity = @broadcast.builder
    @candidate_customers = SurveyResponse.where(survey_activity_id: @survey_activity.id).map { |survey_response|
      {
        id: survey_response.owner_id,
        name: survey_response.owner.name,
        state: survey_response.state,
        checked: @broadcast.receiver_ids.include?(survey_response.owner_id)
      }
    }
  end

  def create
    outcome = Broadcasts::Create.run(user: Current.business_owner, params: params.permit!.to_h)
    flash[:notice] = I18n.t("common.create_successfully_message")

    survey_activity = outcome.result.builder
    return_json_response(outcome, { redirect_to: lines_user_bot_survey_activity_path(survey_activity.survey, survey_activity, business_owner_id: business_owner_id) })
  end

  def update
    outcome = Broadcasts::Update.run(broadcast: Current.business_owner.broadcasts.find(params[:id]), params: params.permit!.to_h, update_attribute: params[:attribute])

    if outcome.valid?
      flash[:notice] = I18n.t("common.update_successfully_message")

      survey_activity = outcome.result.builder
      return_json_response(outcome, { redirect_to: lines_user_bot_survey_activity_path(survey_activity.survey, survey_activity, business_owner_id: business_owner_id) })
    else
      return_json_response(outcome)
    end
  end

  def draft
    broadcast = Current.business_owner.broadcasts.find(params[:id])
    Broadcasts::Draft.run(broadcast: broadcast)

    flash[:notice] = I18n.t("common.update_successfully_message")
    redirect_to lines_user_bot_survey_activity_path(@survey, @activity, business_owner_id: business_owner_id)
  end

  def activate
    broadcast = Current.business_owner.broadcasts.find(params[:id])
    Broadcasts::Activate.run(broadcast: broadcast)

    flash[:notice] = I18n.t("common.update_successfully_message")
    redirect_to lines_user_bot_survey_activity_path(@survey, @activity, business_owner_id: business_owner_id)
  end

  private

  def set_survey
    @survey = Current.business_owner.surveys.find(params[:survey_id])
  end

  def set_activity
    @activity = @survey.activities.find(params[:activity_id])
  end
end
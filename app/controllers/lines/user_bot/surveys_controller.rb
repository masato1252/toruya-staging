# frozen_string_literal: true

class Lines::UserBot::SurveysController < Lines::UserBotDashboardController
  def index
    @surveys = Survey.active.includes(:questions, questions: [:options, :activities, { activities: :activity_slots }])
                    .where(owner: Current.business_owner).order(updated_at: :desc)
  end

  def new
    @survey = Survey.new(owner: Current.business_owner, user: Current.user)
  end

  def show
    @survey = current_user.surveys.find(params[:id])
    @activities = @survey.activities
  end

  def edit
    @survey = current_user.surveys.find(params[:id])
    @attribute = params[:attribute]
  end

  def update
    @survey = current_user.surveys.find(params[:id])
    @attribute = params[:attribute]
    outcome = Surveys::Update.run(
      survey: @survey,
      update_attribute: @attribute,
      attrs: params.permit!.to_h[:survey_form]
    )

    flash[:notice] = t("common.update_successfully_message")
    return_json_response(outcome, { redirect_to: settings_lines_user_bot_survey_path(@survey.id, business_owner_id: business_owner_id, anchor: params[:attribute]) })
  end

  def upsert
    outcome = Surveys::Upsert.run(
      user: Current.business_owner,
      owner: Current.business_owner,
      survey: current_user.surveys.find_by(id: params[:id]),
      title: params[:title],
      description: params[:description],
      questions: params.permit!.to_h[:questions],
      currency: params[:currency].presence || Current.business_owner.currency
    )

    flash[:notice] = t("common.update_successfully_message")
    return_json_response(outcome, { redirect_to: lines_user_bot_surveys_path({ business_owner_id: Current.business_owner.id }) })
  end

  def destroy
    @survey = current_user.surveys.find(params[:id])
    outcome = Surveys::Delete.run(survey: @survey)

    flash[:notice] = t("common.delete_successfully_message")
    return_json_response(outcome, { redirect_to: lines_user_bot_surveys_path({ business_owner_id: Current.business_owner.id }) })
  end

  def activities
    @survey = current_user.surveys.find(params[:id])
    @activities = @survey.activities
  end

  def settings
    @survey = current_user.surveys.find(params[:id])
  end
end
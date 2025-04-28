# frozen_string_literal: true

class SurveysController < Lines::CustomersController
  include ProductLocale

  def show
  end

  def create
    outcome = Surveys::Reply.run(
      survey: survey,
      owner: current_customer,
      answers: params.permit!.to_h[:survey_answers]
    )

    return_json_response(outcome)
  end

  def update
  end

  def reply
    @survey_response = SurveyResponse.find_by!(uuid: params[:uuid])
    @survey = @survey_response.survey
  end

  private

  def survey
    @survey ||= Survey.find_by!(slug: params[:slug])
  end

  def product_social_user
    @product_social_user ||= survey.user.social_user
  end

  def current_owner
    @current_owner ||= survey.user
  end
end

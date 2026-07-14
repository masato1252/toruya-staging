# frozen_string_literal: true

class SurveysController < Lines::CustomersController
  include CompatReadFlags
  include CompatSession
  include ProductLocale

  before_action :load_compat_survey
  before_action :reject_activity_survey, unless: -> { @compat_survey.present? }

  def show
    if @compat_survey
      @compat_social_account = SocialAccount.find_by(user_id: @compat_survey["owner_user_id"])
      render :show_compat, layout: "booking"
      return
    end
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

  def load_compat_survey
    return unless action_name == "show"
    return unless ENV["COMPAT_API_READ_ENABLED"] == "true" && compat_api_configured?

    customer_id = cookies[:verified_customer_id]
    if params[:encrypted_customer_id].present?
      customer_id = MessageEncryptor.decrypt(params[:encrypted_customer_id])
      cookies.clear_across_domains(:verified_customer_id)
      cookies.set_across_domains(:verified_customer_id, customer_id, expires: 20.years.from_now)
    end
    social_user_id =
      params[:social_user_id].presence ||
      params[:social_service_user_id].presence ||
      cookies[:temp_line_social_user_id_of_customer].presence ||
      cookies[:line_social_user_id_of_customer].presence
    context = compat_fetch_v1_json(
      "/surveys/#{params[:slug]}/page_context",
      { customer_id: customer_id, social_user_id: social_user_id }.compact
    )&.dig("data")
    return unless context && compat_public_read_for_owner?(context["owner_user_id"])

    @compat_survey = context
    @compat_customer_id = context["customer_id"]
  end

  def survey
    @survey ||= Survey.find_by!(slug: params[:slug])
  end

  def reject_activity_survey
    if survey.questions.exists?(question_type: 'activity')
      raise ActionController::RoutingError, 'Not Found'
    end
  end

  def product_social_user
    @product_social_user ||= survey.user.social_user
  end

  def current_owner
    @current_owner ||= survey.user
  end
end

class Lines::UserBot::ServicesController < Lines::UserBotDashboardController
  VIDEO_SOLUTION = {
    key: "video",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.video.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.video.description"),
    enabled: true
  }

  AUDIO_SOLUTION = {
    key: "audio",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.audio.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.audio.description"),
    enabled: false
  }

  PDF_SOLUTION = {
    key: "pdf",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.pdf.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.pdf.description"),
    enabled: false
  }

  QUESTIONNAIRE_SOLUTION = {
    key: "questionnaire",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.questionnaire.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.questionnaire.description"),
    enabled: false
  }

  DIAGNOSIS_SOLUTION = {
    key: "diagnosis",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.diagnosis.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.diagnosis.description"),
    enabled: false
  }

  GOALS = [
    {
      key: "collection",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.collection.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.collection.description"),
      enabled: true,
      solutions: [
        VIDEO_SOLUTION,
        AUDIO_SOLUTION,
        PDF_SOLUTION,
        QUESTIONNAIRE_SOLUTION,
        DIAGNOSIS_SOLUTION
      ]
    },
    {
      key: "customers",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.customers.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.customers.description"),
      enabled: true,
      solutions: [
        VIDEO_SOLUTION,
        AUDIO_SOLUTION
      ]
    },
    {
      key: "price",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.price.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.price.description"),
      enabled: true,
      solutions: [
        VIDEO_SOLUTION,
        AUDIO_SOLUTION
      ]
    },
    {
      key: "upsell",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.upsell.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.upsell.description"),
      enabled: false,
      solutions: [
        VIDEO_SOLUTION
      ]
    }
  ]
  def new
    # @sale_templates = SaleTemplate.all
    # if booking_page = BookingPage.find_by(id: params[:booking_page_id])
    #   @selected_booking_page = BookingPageSerializer.new(booking_page).attributes_hash
    # end
  end

  def create
    outcome = ::OnlineServices::Create.run(
      user: current_user,
      name: params[:name],
      selected_goal: params[:selected_goal],
      selected_solution: params[:selected_solution],
      end_time: params[:end_time].permit!.to_h,
      upsell: params[:upsell].permit!.to_h,
      content: params[:content].permit!.to_h,
      selected_company: params[:selected_company].permit!.to_h,
    )

    return_json_response(outcome, { online_service_id: outcome.result&.id })
  end
end

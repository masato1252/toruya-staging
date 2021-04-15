# frozen_string_literal: true

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

    return_json_response(outcome, { online_service_slug: outcome.result&.slug })
  end

  def index
    @online_services = current_user.online_services.order("updated_at DESC")
  end

  def show
    @service = current_user.online_services.find(params[:id])
    @upsell_sale_page = @service.sale_page.serializer.attributes_hash if @service.sale_page
    @online_service_hash = OnlineServiceSerializer.new(@service).attributes_hash.merge(demo: false, light: false)
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

# frozen_string_literal: true

class OnlineServicesController < Lines::CustomersController
  include ProductLocale
  include CompatSession
  layout "booking"

  before_action :online_service
  skip_before_action :verify_authenticity_token, only: [:watch_lesson, :watch_episode]

  def show
    if compat_public_read_for_owner?(online_service.user_id) && current_customer.blank?
      render :show_compat_guest
      return
    end

    if compat_public_read_for_owner?(online_service.user_id) && current_customer.present?
      render :show_compat_member
      return
    end

    @service_member = online_service.online_service_customer_relations.where(customer: current_customer).last

    @online_service_hash =
      if @online_service.course_like?
        CourseSerializer.new(@online_service, { params: { service_member: @service_member }}).attributes_hash
      elsif @online_service.membership?
        MembershipSerializer.new(@online_service).attributes_hash
      else
        OnlineServiceSerializer.new(@online_service).attributes_hash.merge(demo: false, light: false)
      end

    if params[:episode_id]
      @episode = @online_service.episodes.find_by(id: params[:episode_id])
    end
  end

  def customer_status
    # authorize owner and customer
    @relation = online_service.online_service_customer_relations.where(customer: current_customer).last

    if @relation.present?
      @customer = current_customer
      @is_owner = false
      @able_to_change_credit_card = OnlineServiceCustomerRelations::ChangeCreditCardAbility.run!(relation: @relation)

      render layout: "customer_user_bot"
    end
  end

  def watch_lesson
    if compat_public_read_for_owner?(online_service.user_id)
      return render_compat_watch_response(:lesson, params[:lesson_id])
    end

    outcome = Lessons::Watch.run(online_service: online_service, customer: current_customer, lesson: online_service.lessons.find(params[:lesson_id]))

    return_json_response(outcome, { watched_lesson_ids: outcome.result&.watched_lesson_ids || []})
  end

  def watch_episode
    if compat_public_read_for_owner?(online_service.user_id)
      return render_compat_watch_response(:episode, params[:episode_id])
    end

    outcome = Episodes::Watch.run(customer: current_customer, episode: online_service.episodes.find(params[:episode_id]))

    return_json_response(outcome, { watched_episode_ids: outcome.result&.watched_episode_ids || []})
  end

  def tagged_episodes
    episodes = Episodes::Tagged.run!(online_service: online_service, tag: params[:tag])

    render json: { episodes: episodes.map { |episode| EpisodeSerializer.new(episode).attributes_hash } }
  end

  def search_episodes
    episodes = Episodes::Search.run!(online_service: online_service, keyword: params[:keyword])

    render json: { episodes: episodes.map { |episode| EpisodeSerializer.new(episode).attributes_hash } }
  end

  private

  def online_service
    @online_service ||= OnlineService.find_by!(slug: params[:slug])
  end

  def current_owner
    online_service.user
  end

  def product_social_user
    online_service.user.social_user
  end

  def render_compat_watch_response(content_type, content_id)
    customer = current_customer
    unless customer
      render json: { status: "failed", error_message: "顧客情報が見つかりません" }, status: :unprocessable_entity
      return
    end

    social_customer = current_social_customer
    response = compat_v1_put_response(
      "/online_services/#{params[:slug]}/#{content_type == :lesson ? "lessons" : "episodes"}/#{content_id}",
      {
        customer_id: customer.id,
        social_service_user_id: social_customer&.social_user_id,
        encrypted_customer_id: params[:encrypted_customer_id],
        encrypted_social_service_user_id: params[:encrypted_social_service_user_id]
      }.compact
    )

    unless response
      render json: { status: "failed", error_message: "視聴状態を更新できません" }, status: :bad_gateway
      return
    end

    render json: response[:body], status: response[:status]
  end
end

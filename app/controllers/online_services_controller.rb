# frozen_string_literal: true

class OnlineServicesController < Lines::CustomersController
  include ProductLocale
  layout "booking"

  before_action :online_service
  skip_before_action :verify_authenticity_token, only: [:watch_lesson, :watch_episode]

  def show
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
    outcome = Lessons::Watch.run(online_service: online_service, customer: current_customer, lesson: online_service.lessons.find(params[:lesson_id]))

    return_json_response(outcome, { watched_lesson_ids: outcome.result&.watched_lesson_ids || []})
  end

  def watch_episode
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
end

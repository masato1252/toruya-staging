# frozen_string_literal: true

class Lines::UserBot::CustomersController < Lines::UserBotDashboardController
  include CrossAccountRedirect
  redirect_to_correct_owner_for :customers, param_key: :customer_id, only: [:details, :reply_message, :delete_message, :unread_message]
  redirect_to_correct_owner_for :customers, param_key: :id, only: [:toggle_reminder_permission, :delete]

  def index
    authorize! :read, :customers_dashboard

    if compat_read_enabled?
      # List / counts / notifications load via v1 compat (CustomerServices + read APIs).
      @customer = nil
      @reservation = nil
      @total_customers_number = nil
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_id(current_user&.id) || Current.business_owner&.id
      @notification_messages = compat_customer_notification_messages(owner_id)
      draft_message_content = Rails.cache.read(draft_message_content_hash_cache_key)
      @draft_message_content = draft_message_content ? JSON.parse(draft_message_content) : {}
      return
    end

    @customers =
      Current.business_owner
      .customers
      .includes(:social_customer, :rank, :contact_group, updated_by_user: :profile)
      .order("updated_at DESC")
      .limit(::Customers::Search::PER_PAGE)

    @customer =
      Current.business_owner
      .customers
      .includes(:rank, :contact_group, :social_customer).find_by(id: params[:customer_id])

    @reservation = ReservationCustomer.find_by(customer_id: params[:customer_id], reservation_id: params[:reservation_id])&.reservation

    if shop
      @add_reservation_path = form_shop_reservations_path(shop, params[:reservation_id])
    end

    @total_customers_number = Current.business_owner.customers.count

    # Notifications START
    @notification_messages = Notifications::PendingCustomerReservationsPresenter.new(view_context, Current.business_owner).data.compact
    # Notifications END

    draft_message_content = Rails.cache.read(draft_message_content_hash_cache_key)
    @draft_message_content = draft_message_content ? JSON.parse(draft_message_content) : {}
  end

  def details
    @customer = Current.business_owner.customers.contact_groups_scope(current_user_staff).find(params[:customer_id])
    authorize! :read, @customer

    render template: "customers/show"
  end

  def filter
    customers = ::Customers::CharFilter.run(
      super_user: Current.business_owner,
      current_user_staff: current_user_staff,
      pattern_number: params[:pattern_number],
      page: params[:page].presence || 1
    ).result

    render_customers_json(customers)
  end

  def recent
    customers =
      Current.business_owner
      .customers
      .includes(:social_customer, :rank, :contact_group, updated_by_user: :profile)
      .order("updated_at DESC, id DESC")
      .where(
        "customers.updated_at < :last_updated_at OR
        (customers.updated_at = :last_updated_at AND customers.id < :last_updated_id)",
        last_updated_at: params["last_updated_at"] ? Time.parse(params["last_updated_at"]) : Time.current,
        last_updated_id: params["last_updated_id"] || INTEGER_MAX)
      .limit(::Customers::Search::PER_PAGE)

    render_customers_json(customers)
  end

  def search
    customers = ::Customers::Search.run(
      super_user: Current.business_owner,
      current_user_staff: current_user_staff,
      keyword: params[:keyword],
      page: params[:page].presence || 1
    ).result

    render_customers_json(customers)
  end

  def save
    outcome = ::Customers::Store.run(user: Current.business_owner, current_user: current_user, params: convert_params(params.permit!.to_h))

    customer = outcome.result
    return_json_response(outcome, { redirect_to: SiteRouting.new(view_context).customers_path(customer&.user_id, customer_id: customer&.id) })
  end

  def data_changed
    authorize! :edit, Customer

    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil)
      payload = owner_id && compat_fetch_v1_json(
        "/lines/user_bot/owner/#{owner_id}/customers/data_changed/#{params[:reservation_customer_id]}"
      )
      @data_change = payload&.dig("data")
      return head :not_found unless @data_change

      @compat_owner_id = owner_id
      return render template: "customers/data_changed", layout: false
    end

    @reservation_customer = ReservationCustomer.find(params[:reservation_customer_id])
    @customer = @reservation_customer.customer
    @reservation = @reservation_customer.reservation

    render template: "customers/data_changed", layout: false
  end

  def save_changes
    authorize! :edit, Customer

    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil)
      result = owner_id && compat_v1_patch(
        "/lines/user_bot/owner/#{owner_id}/customers/save_changes/#{params[:reservation_customer_id]}"
      )
      return head(result&.dig("status") == "successful" ? :ok : :unprocessable_entity)
    end

    outcome = ::Customers::RequestUpdate.run(reservation_customer: ReservationCustomer.find(params[:reservation_customer_id]))

    if outcome.invalid?
      # Rollbar.warning("Update customer changed data failed",
      #   errors_messages: outcome.errors.full_messages.join(", "),
      #   errors_details: outcome.errors.details,
      #   params: params
      # )
    end

    head :ok
  end

  def toggle_reminder_permission
    customer = Current.business_owner.customers.contact_groups_scope(current_user_staff).find(params[:id])
    customer.update(reminder_permission: !customer.reminder_permission)

    render json: { reminder_permission: customer.reminder_permission }
  end

  def reply_message
    customer = Current.business_owner.customers.contact_groups_scope(current_user_staff).find(params[:customer_id])

    if params[:message].present?
      outcome = SocialMessages::Create.run(
        social_customer: customer.social_customer,
        staff: current_user_staff,
        content: params[:message],
        readed: true,
        message_type: SocialMessage.message_types[:staff],
        schedule_at: params[:schedule_at] ? Time.zone.parse(params[:schedule_at]) : nil
      )
    end

    if params[:image].present?
      outcome = SocialMessages::Create.run(
        social_customer: customer.social_customer,
        staff: current_user_staff,
        content: {
          originalContentUrl: "tmp_original_content_url",
          previewImageUrl: "tmp_preview_image_url"
        }.to_json,
        image: params[:image],
        readed: true,
        message_type: SocialMessage.message_types[:staff],
        content_type: SocialMessages::Create::IMAGE_TYPE,
        schedule_at: params[:schedule_at] ? Time.zone.parse(params[:schedule_at]) : nil
      )
    end

    if outcome.valid? && draft_message_content = Rails.cache.read(draft_message_content_hash_cache_key)
      content = JSON.parse(draft_message_content)
      content.delete(customer.id.to_s)
      Rails.cache.write(draft_message_content_hash_cache_key, content.to_json)
    end

    return_json_response(outcome, { redirect_to: params[:schedule_at] ? SiteRouting.new(view_context).customers_path(customer.user_id, customer_id: customer.id, target_view: Customer::DASHBOARD_TARGET_VIEWS[:messages]) : nil})
  end

  def save_draft_message
    Rails.cache.write(draft_message_content_hash_cache_key, params[:draft_message_content].to_json)

    head :ok
  end

  def delete_message
    message = Current.business_owner.social_account.social_messages.find(params[:message_id])

    unless message.sent_at
      message.destroy
    end

    customer = Current.business_owner.customers.contact_groups_scope(current_user_staff).find(params[:customer_id])

    render json: {
      status: "successful",
      redirect_to: SiteRouting.new(view_context).customers_path(customer.user_id, customer_id: customer.id, target_view: Customer::DASHBOARD_TARGET_VIEWS[:messages])
    }
  end

  def unread_message
    customer = Current.business_owner.customers.contact_groups_scope(current_user_staff).find(params[:customer_id])
    message = Current.business_owner.social_account.social_messages.customer.where(social_customer_id: customer.social_customer.id).order("id").last

    outcome = SocialMessages::Unread.run(
      social_customer: customer.social_customer,
      social_message: message
    )

    render json: json_response(outcome)
  end

  def find_duplicate_customers
    customers = Current.business_owner
      .customers
      .contact_groups_scope(current_user_staff)
      .where("
      (phonetic_last_name ilike :last_name AND
      phonetic_first_name ilike :first_name) OR
      (last_name ilike :last_name AND
      first_name ilike :first_name)", last_name: "%#{params[:last_name].strip}%", first_name: "%#{params[:first_name].strip}%")

    render_customers_json(customers)
  end

  def delete
    authorize! :edit, Customer

    customer = Current.business_owner.customers.contact_groups_scope(current_user_staff).find(params[:id])
    outcome = Customers::Delete.run(customer: customer)

    render json: json_response(outcome)
  end

  def csv
    result = ::Customers::Csv.run!(user: Current.business_owner)
    send_data result, filename: "customers.csv"
  end

  private

  def compat_customer_notification_messages(owner_id)
    return [] if owner_id.blank?

    payload = fetch_v1_json(
      "/lines/user_bot/owner/#{owner_id}/notifications",
      { current_user_id: current_user&.id }.compact
    )
    data = payload.is_a?(Hash) ? (payload["data"] || payload[:data] || {}) : {}
    data = data.deep_stringify_keys if data.respond_to?(:deep_stringify_keys)
    pending = Array(data["pending_customer_reservations"])
    return [] if pending.blank?

    message = I18n.t(
      "notifications.pending_customer_reservation_need_confirm",
      number: pending.size
    )
    href = pending.first["href"]
    text = I18n.t("notifications.pending_customer_reservation_confirm")
    ["#{message} #{view_context.link_to(text, href)}"]
  rescue StandardError => e
    Rails.logger.warn("[CustomersController] compat notifications failed: #{e.message}")
    []
  end

  def render_customers_json(customers)
    render json: { customers: customers.map { |customer| CustomerOptionSerializer.new(customer).attributes_hash } }
  end

  def draft_message_content_hash_cache_key
    "draft_message_content_#{Current.business_owner.id}_v1"
  end
end

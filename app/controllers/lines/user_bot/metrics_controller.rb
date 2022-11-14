# frozen_string_literal: true

class Lines::UserBot::MetricsController < Lines::UserBotDashboardController
  def index
  end

  def sale_pages; end

  def sale_pages_visits
    render json: sale_pages_visits_metric_data(uniq_sale_page_ids)
  end

  def sale_pages_conversions
    render json: sale_pages_conversions_metric_data(uniq_sale_page_ids)
  end

  def online_services
    @online_services = current_user.online_services.order("updated_at DESC")
  end

  def online_service; end

  def online_service_sale_pages_visits
    sale_page_ids = SalePage.where(id: uniq_sale_page_ids, product_id: params[:id], product_type: 'OnlineService').pluck(:id)

    render json: sale_pages_visits_metric_data(params[:demo] ? uniq_sale_page_ids : sale_page_ids)
  end

  def online_service_sale_pages_conversions
    sale_page_ids = SalePage.where(id: uniq_sale_page_ids, product_id: params[:id], product_type: 'OnlineService').pluck(:id)

    render json: sale_pages_conversions_metric_data(params[:demo] ? uniq_sale_page_ids : sale_page_ids)
  end

  private

  def metric_period
    metric_start_time..Time.current
  end

  def visit_scope
    params[:demo] ? Ahoy::Visit.where(product_type: "SalePage") : Ahoy::Visit.where(owner_id: current_user.id, product_type: "SalePage")
  end

  def uniq_sale_page_ids
    params[:demo] ? visit_scope.select(:product_id).distinct(:product_id).pluck(:product_id).sample(3) : visit_scope.where(started_at: metric_period).select(:product_id).distinct(:product_id).pluck(:product_id)
  end

  def metric_start_time
    31.days.ago.beginning_of_day
  end

  def sale_pages_visits_metric_data(sale_page_ids)
    metrics = sale_page_ids.each_with_object({}) do |product_id, h|
      start_time = metric_start_time

      h[product_id] = 4.times.map do |i|
        end_time = (start_time + 7.days).end_of_day
        count = visit_scope.where(product_id: product_id, product_type: "SalePage").where(started_at: start_time..end_time).count

        start_time = end_time.next_day.beginning_of_day

        params[:demo] ? rand(100) : count
      end
    end
    # metrics = {
    #   382=>[45, 34, 0, 0],
    #   384=>[2, 8, 32, 0],
    #   386=>[0, 1, 2, 0]
    # }

    start_time = metric_start_time
    labels = 4.times.map do |i|
      end_time = (start_time + 7.days).end_of_day
      label = "#{I18n.l(start_time, format: :date)} ~ #{I18n.l(end_time, format: :date)}"
      start_time = end_time.next_day.beginning_of_day

      label
    end
    # labels = [
    #  "2022/11/07(月) ~ 2022/11/14(月)",
    #  "2022/11/15(火) ~ 2022/11/22(火)",
    #  "2022/11/23(水) ~ 2022/11/30(水)",
    #  "2022/12/01(木) ~ 2022/12/08(木)"
    # ]

    sale_pages = SalePage.where(id: sale_page_ids).includes(:product).to_a
    datasets = metrics.map do |product_id, visit_counts|
      product = sale_pages.find { |page| page.id == product_id }

      rgb_color = "#{rand(255)}, #{rand(255)}, #{rand(255)}"
      {
        label: product&.internal_name&.presence || product&.internal_product_name || product_id,
        data: visit_counts,
        borderColor: "rgb(#{rgb_color})",
        cubicInterpolationMode: 'monotone',
        tension: 0.4
      }
    end

    # {
    #   labels,
    #   datasets: [
    #     {
    #       label: 'Dataset 1',
    #       data: labels.map(() => 100),
    #       borderColor: 'rgb(255, 99, 132)',
    #       backgroundColor: 'rgba(255, 99, 132, 0.5)',
    #     },
    #     {
    #       label: 'Dataset 2',
    #       data: labels.map(() => 200),
    #       borderColor: 'rgb(53, 162, 235)',
    #       backgroundColor: 'rgba(53, 162, 235, 0.5)',
    #     },
    #   ]
    # }
    {
      labels: labels,
      datasets: datasets
    }
  end

  def sale_pages_conversions_metric_data(sale_page_ids)
    sale_pages = SalePage.where(id: sale_page_ids).includes(:product).to_a

    metrics = sale_page_ids.map do |product_id|
      sale_page = sale_pages.find { |page| page.id == product_id }
      visit_count = visit_scope.where(product_id: product_id, product_type: "SalePage").where(started_at: metric_period).count
      visit_count = params[:demo] ? rand(6..10) : count
      purchased_count =
        if sale_page&.is_booking_page?
          nil
        else
          OnlineServiceCustomerRelation.where(paid_at: metric_period, sale_page_id: product_id).count
          params[:demo] ? rand(1..3) : count
        end

      {
        label: sale_page&.internal_name&.presence || sale_page&.internal_product_name || product_id,
        visit_count: visit_count,
        purchased_count: purchased_count,
        rate: purchased_count ? purchased_count / visit_count.to_f : nil,
        format_rate: purchased_count ? helpers.number_to_percentage(purchased_count * 100 / visit_count.to_f, precision: 1) : nil
      }
    end

    metrics.sort_by { |m| m[:rate] ? -m[:rate] : -1_000 }.sort_by { |m| -m[:visit_count] }
  end
end

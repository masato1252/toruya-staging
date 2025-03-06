# frozen_string_literal: true

module Metrics
  class SalePagesVisits < ActiveInteraction::Base
    object :user
    array :sale_page_ids do
      integer
    end
    object :metric_period, class: Range
    boolean :demo, default: false

    def execute
      if demo
        return {
          "labels":[
            "2022/10/17(月) ~ 2022/10/24(月)",
            "2022/10/25(火) ~ 2022/11/01(火)",
            "2022/11/02(水) ~ 2022/11/09(水)",
            "2022/11/10(木) ~ 2022/11/17(木)"
          ],
          "datasets":[
            {
              "label":"オープンキャンペーン美bodyパーソナルセッション予約ページ",
              "data":[15, 86, 81, 44],
              "borderColor":"rgb(254, 151, 161)",
              "cubicInterpolationMode":"monotone",
              "tension":0.4
            },
            {
              "label":"Quick３セッション予約ページ",
              "data":[83, 80, 88, 98],
              "borderColor":"rgb(91, 238, 129)",
              "cubicInterpolationMode":"monotone",
              "tension":0.4
            },
            {
              "label":"体験パーソナルセッション予約ページ",
              "data":[6, 44, 95, 3],
              "borderColor":"rgb(99, 10, 166)",
              "cubicInterpolationMode":"monotone",
              "tension":0.4
            }
          ]
        }
      end

      # Calculate all days in the period
      days = []
      current_day = metric_period.begin.beginning_of_day

      while current_day <= metric_period.end.end_of_day
        days << current_day.to_date
        current_day = current_day.next_day
      end

      # Fetch all visit data in a single query, grouped by sale page and day
      visits_by_date = Ahoy::Visit
        .where(owner_id: user.id, product_type: "SalePage")
        .where(product_id: sale_page_ids)
        .where(started_at: metric_period)
        .select("product_id, DATE(started_at) as visit_date, COUNT(*) as visit_count")
        .group("product_id, DATE(started_at)")
        .order("product_id, DATE(started_at)")
        .map { |v| [v.product_id, v.visit_date.to_date, v.visit_count] }

      # Organize data by sale page and date
      visit_counts = {}
      sale_pages.each do |sale_page|
        visit_counts[sale_page.id] = {}
        days.each do |day|
          visit_counts[sale_page.id][day] = 0
        end
      end

      # Fill in the actual counts from the query results
      visits_by_date.each do |product_id, date, count|
        if visit_counts[product_id] && visit_counts[product_id][date]
          visit_counts[product_id][date] = count
        end
      end

      # Create the final metrics structure
      metrics = sale_pages.each_with_object({}) do |sale_page, h|
        h[sale_page.id] = days.map { |day| visit_counts[sale_page.id][day] }
      end

      # Generate labels for each day
      labels = days.map { |day| I18n.l(day, format: :short) }

      datasets = metrics.map do |sale_page_id, visit_counts|
        product = sale_pages.find { |page| page.id == sale_page_id }

        rgb_color = "#{rand(255)}, #{rand(255)}, #{rand(255)}"
        {
          label: product&.internal_sale_name,
          data: visit_counts,
          borderColor: "rgb(#{rgb_color})",
          cubicInterpolationMode: 'monotone',
          tension: 0.4
        }
      end

      {
        labels: labels,
        datasets: datasets
      }
    end

    private

    def sale_pages
      @sale_pages ||= SalePage.active.where(id: sale_page_ids).includes(:product).to_a
    end
  end
end

# frozen_string_literal: true

module Metrics
  class BookingPagesVisits < ActiveInteraction::Base
    object :user
    array :booking_page_ids do
      integer
    end
    time :metric_start_time
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

      visit_scope = Ahoy::Visit.where(owner_id: user.id, product_type: "BookingPage")
      metrics = booking_pages.each_with_object({}) do |booking_page, h|
        start_time = metric_start_time

        h[booking_page.id] = 4.times.map do |i|
          end_time = (start_time + 7.days).end_of_day
          count = visit_scope.where(product_id: booking_page.id, product_type: "BookingPage").where(started_at: start_time..end_time).count

          start_time = end_time.next_day.beginning_of_day

          count
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

      datasets = metrics.map do |booking_page_id, visit_counts|
        booking_page = booking_pages.find { |page| page.id == booking_page_id }

        rgb_color = "#{rand(255)}, #{rand(255)}, #{rand(255)}"
        {
          label: booking_page&.name,
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

    private

    def booking_pages
      @booking_pages ||= BookingPage.active.where(id: booking_page_ids).to_a
    end
  end
end
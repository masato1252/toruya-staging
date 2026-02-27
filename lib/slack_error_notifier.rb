# frozen_string_literal: true

require "net/http"
require "json"

class SlackErrorNotifier
  WEBHOOK_URL_ENV_KEY = "SLACK_ERROR_WEBHOOK_URL"

  class << self
    def notify(exception, context = {})
      return unless webhook_url.present?

      payload = build_payload(exception, context)

      Thread.new do
        post_to_slack(payload)
      rescue StandardError => e
        Rails.logger.error("[SlackErrorNotifier] Failed to send: #{e.message}")
      end
    rescue StandardError => e
      Rails.logger.error("[SlackErrorNotifier] Failed to build payload: #{e.message}")
    end

    private

    def webhook_url
      ENV[WEBHOOK_URL_ENV_KEY]
    end

    def environment_label
      env = Rails.configuration.x.env
      if env.production?
        "本番環境"
      elsif env.staging?
        "ステージング環境"
      else
        env.to_s
      end
    end

    def mention_text(mention: false)
      mention ? "<!channel> " : ""
    end

    def build_payload(exception, context)
      mention = context.delete(:mention) || false
      blocks = []

      blocks << {
        type: "header",
        text: {
          type: "plain_text",
          text: ":rotating_light: [#{environment_label}] エラー通知",
          emoji: true
        }
      }

      error_lines = []
      error_lines << "*エラー種別:* `#{exception.class}`"
      error_lines << "*エラー内容:* #{truncate(exception.message, 500)}"
      if (location = extract_location(exception))
        error_lines << "*発生箇所:* `#{location}`"
      end
      if context[:source].present?
        error_lines << "*発生元:* #{context[:source]}"
      end

      blocks << {
        type: "section",
        text: { type: "mrkdwn", text: error_lines.join("\n") }
      }

      context_lines = []
      context_lines << "*user_id:* #{context[:user_id]}" if context[:user_id].present?
      context_lines << "*customer_id:* #{context[:customer_id]}" if context[:customer_id].present?
      if context[:request_method].present? && context[:request_path].present?
        context_lines << "*リクエスト:* `#{context[:request_method]} #{context[:request_path]}`"
      end
      context_lines << "*IP:* #{context[:remote_ip]}" if context[:remote_ip].present?
      context_lines << "*ジョブ:* `#{context[:job_name]}`" if context[:job_name].present?
      context_lines << "*引数:* #{truncate(context[:job_args].to_s, 300)}" if context[:job_args].present?

      if context_lines.any?
        blocks << { type: "divider" }
        blocks << {
          type: "section",
          text: { type: "mrkdwn", text: context_lines.join("\n") }
        }
      end

      if exception.backtrace.present?
        app_trace = exception.backtrace
          .select { |line| line.include?("app/") || line.include?("lib/") }
          .first(5)
        trace = app_trace.any? ? app_trace : exception.backtrace.first(5)

        blocks << { type: "divider" }
        blocks << {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "*バックトレース:*\n```#{trace.join("\n")}```"
          }
        }
      end

      {
        text: "#{mention_text(mention: mention)}[#{environment_label}] #{exception.class}: #{truncate(exception.message, 100)}",
        blocks: blocks
      }
    end

    def extract_location(exception)
      return nil unless exception.backtrace.present?

      exception.backtrace.find { |line| line.include?("app/") || line.include?("lib/") } ||
        exception.backtrace.first
    end

    def truncate(text, length)
      return "" if text.nil?

      text.length > length ? "#{text[0...length]}..." : text
    end

    def post_to_slack(payload)
      uri = URI.parse(webhook_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error("[SlackErrorNotifier] Slack responded with #{response.code}: #{response.body}")
      end
    end
  end
end

# frozen_string_literal: true

module Seeders
  class Plan
    PLANS_FILE = Rails.root.join("db/data/plans.json")

    def initialize(plans)
      ::Plan.transaction do
        plans.each do |plan_attrs|
          ::Plan.find_or_create_by!(plan_attrs)
        end
      end
    end

    def self.seed!
      json = PLANS_FILE.read
      # Remove comments from the file. Note that JSON doesn't actually allow
      # comments, but we want them anyways.
      json = json.gsub(/^\s*\#.*\n/, "")

      new(JSON.parse(json)) && true
    end

    def self.dump!
      plans = ::Plan.order(:position).map do |plan|
        attributes = plan.attributes.slice(*%w(
          position
          level
        ))
      end

      PLANS_FILE.open("w") do |file|
        file.puts <<-COMMENT.strip_heredoc
          # This file is auto-generated from the current state of plans types in the
          # database. Instead of editing this file, please use migrations to make changes
          # to current badges.
        COMMENT

        file.puts JSON.pretty_generate(plans)
      end
    end
  end
end

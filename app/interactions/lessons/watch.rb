# frozen_string_literal: true

module Lessons
  class Watch < ActiveInteraction::Base
    object :customer
    object :lesson
    object :online_service

    def execute
      relation = online_service.available_online_service_customer_relations.find_by!(customer: customer)
      relation.update(watched_lesson_ids: relation.watched_lesson_ids.push(lesson.id).map(&:to_s).uniq)
      relation
    end
  end
end

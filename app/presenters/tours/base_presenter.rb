# frozen_string_literal: true

module Tours
  class BasePresenter
    attr_reader :user, :h

    def initialize(view_context, user)
      @h = view_context
      @user = user
    end

    def title
      raise NotImplementedError, "Subclass must implement this method"
    end

    def tour_path
      raise NotImplementedError, "Subclass must implement this method"
    end

    def steps
      raise NotImplementedError, "Subclass must implement this method"
    end

    def completed?
      raise NotImplementedError, "Subclass must implement this method"
    end

    def last_step_task_path
      steps.last.tasks.last.setting_path
    end

    def first_undo_task
      tasks.find {|task| !task.done }
    end

    private

    def tasks
      @tasks ||= steps.map { |s| s.tasks }.flatten
    end
  end
end

# frozen_string_literal: true

namespace :filtered_outcome do
  task :remove_expired_file => :environment do
    FilteredOutcome.where(aasm_state: :completed).where("created_at < ?", FilteredOutcome::EXPIRED_DAYS.days.ago).find_each do |filtered_outcome|
      FilteredOutcomes::Remove.run!(filtered_outcome: filtered_outcome)
    end
  end
end

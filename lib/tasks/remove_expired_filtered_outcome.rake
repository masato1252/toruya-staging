namespace :filtered_outcome do
  task :remove_expired_file => :environment do
    FilteredOutcome.where("created_at < ?", 7.days.ago).find_each do |filtered_outcome|
      FilteredOutcomes::Remove.run!(filtered_outcome: filtered_outcome)
    end
  end
end

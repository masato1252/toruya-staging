namespace :filtered_outcome do
  task :remove_expired_file => :environment do
    FilterOutcome.where("created_at < ?", 7.days.ago).find_each do |filter_outcome|
      FilterOutcomes::Remove.run!(filter_outcome: filter_outcome)
    end
  end
end

class FilterOutcomes::Remove < ActiveInteraction::Base
  object :filtered_outcome

  def execute
    filtered_outcome.remove_file!
    filtered_outcome.remove!
  end
end

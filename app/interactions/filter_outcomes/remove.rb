class FilterOutcomes::Remove < ActiveInteraction::Base
  object :filter_outcome

  def execute
    filter_outcome.remove_file!
    filter_outcome.remove!
  end
end

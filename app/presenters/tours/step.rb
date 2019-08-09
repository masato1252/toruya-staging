module Tours
  class Step
    include ActiveAttr::MassAssignment
    include ActiveAttr::Attributes

    attribute :done
    attribute :percentage
    attribute :title
    attribute :tasks
  end
end

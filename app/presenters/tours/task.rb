module Tours
  class Task
    include ActiveAttr::MassAssignment
    include ActiveAttr::AttributeDefaults

    attribute :done
    attribute :title
    attribute :setting_path
    attribute :setting_path_condition, default: true
    attribute :accessable_controller_in_tour, default: []
  end
end

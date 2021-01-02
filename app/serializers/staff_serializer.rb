class StaffSerializer
  include FastJsonapi::ObjectSerializer
  attribute :id, :introduction

  attribute :name do |staff|
    staff.name
  end

  attribute :picture_url do |staff|
    ApplicationController.helpers.staff_picture_url(staff, "360")
  end
end

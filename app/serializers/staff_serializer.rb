class StaffSerializer
  include FastJsonapi::ObjectSerializer
  attribute :id, :introduction

  attribute :name do |staff|
    staff.name
  end

  attribute :picture_url do |shop|
    ApplicationController.helpers.staff_picture_url(shop, "180x180")
  end
end

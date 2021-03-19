# frozen_string_literal: true

class StaffSerializer
  include JSONAPI::Serializer
  attribute :id, :introduction

  attribute :name do |staff|
    staff.name
  end

  attribute :picture_url do |staff|
    ApplicationController.helpers.staff_picture_url(staff, "360")
  end

  attribute :editable do |staff|
    true
  end
end

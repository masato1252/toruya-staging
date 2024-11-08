# frozen_string_literal: true

class SocialRichMenuSerializer
  include JSONAPI::Serializer
  attribute :id, :internal_name, :bar_label, :social_name, :layout_type, :actions, :default, :current

  attribute :image_url do |rich_menu|
    Images::Process.run!(image: rich_menu.image, resize: "2500") || rich_menu.default_image_url
  end
end

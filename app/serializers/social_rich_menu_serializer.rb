# frozen_string_literal: true

class SocialRichMenuSerializer
  include JSONAPI::Serializer
  attribute :internal_name, :bar_label, :social_name, :layout_type, :actions

  attribute :image_url do |rich_menu|
    Images::Process.run!(image: rich_menu.image, resize: "2500") || "https://toruya.s3.ap-southeast-1.amazonaws.com/public/rich_menus/#{rich_menu.social_name}.png"
  end
end
